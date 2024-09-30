use godot::{obj::WithBaseField, prelude::*};

use super::resource_registry::ResourceRegistry;

/// The [ResourceProcessor] allows Godot [Resource] objects to run a process
/// function every frame. Resources must register with the [ResourceRegistry]
/// associated with this [ResourceProcessor] in order to be processed from
/// the scene tree.
#[derive(GodotClass)]
#[class(init, base=Node)]
pub struct ResourceProcessor {
    base: Base<Node>,
    #[export]
    registry: Gd<ResourceRegistry>,
    initialized: bool,
}

#[godot_api]
impl INode for ResourceProcessor {
    fn process(&mut self, delta: f64) {
        if !self.initialized {
            // Add any child nodes from the registry
            let children = self.registry.bind().get_children();
            for child in children.iter_shared() {
                self.base_mut().add_child(child);
            }

            // Add any future children that get added to the registry
            let ptr = self.to_gd();
            let method = Callable::from_object_method(&ptr, "add_child");
            self.registry.connect("child_added".into(), method);

            // Remove any children that get removed from the registry
            let method = Callable::from_object_method(&ptr, "remove_child");
            self.registry.connect("child_removed".into(), method);

            self.initialized = true;
        }
        self.registry.bind_mut().process(delta);
    }
}
