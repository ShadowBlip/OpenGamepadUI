use godot::{obj::WithBaseField, prelude::*};

use super::resource_registry::ResourceRegistry;

/// Helper node to allow [Resource] objects to run during the process loop.
///
/// The [ResourceProcessor] allows Godot [Resource] objects to run a [method process] function every frame. By design, Godot [Resource] objects do not have access to the scene tree and must be "invited" in by a [Node] in the scene. This node serves as that entrypoint, and should be added to the scene tree to execute [method process] on any [Resource] objects registered with a [ResourceRegistry].
///
/// Resources must register with the [ResourceRegistry] using [method ResourceRegistry.register] associated with this [ResourceProcessor] in order to be processed from the scene tree.
#[derive(GodotClass)]
#[class(init, base=Node)]
pub struct ResourceProcessor {
    base: Base<Node>,
    #[export]
    registry: Option<Gd<ResourceRegistry>>,
    initialized: bool,
}

#[godot_api]
impl INode for ResourceProcessor {
    fn process(&mut self, delta: f64) {
        if self.registry.is_none() {
            return;
        }
        if !self.initialized {
            // Add any child nodes from the registry
            let children = {
                let registry = self.registry.as_mut().unwrap();
                registry.bind().get_children()
            };
            for child in children.iter_shared() {
                self.base_mut().add_child(&child);
            }

            // Add any future children that get added to the registry
            let ptr = self.to_gd();
            let method = Callable::from_object_method(&ptr, "add_child");
            {
                let registry = self.registry.as_mut().unwrap();
                registry.connect("child_added", &method);
            }

            // Remove any children that get removed from the registry
            let method = Callable::from_object_method(&ptr, "remove_child");
            {
                let registry = self.registry.as_mut().unwrap();
                registry.connect("child_removed", &method);
            }

            self.initialized = true;
        }
        let registry = self.registry.as_mut().unwrap();
        registry.bind_mut().process(delta);
    }
}
