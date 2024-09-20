use godot::prelude::*;

use super::resource_registry::ResourceRegistry;

#[derive(GodotClass)]
#[class(init, base=Node)]
pub struct ResourceProcessor {
    base: Base<Node>,
    #[export]
    registry: Gd<ResourceRegistry>,
}

#[godot_api]
impl INode for ResourceProcessor {
    //fn init(base: Base<Self::Base>) -> Self {
    //    // Load the registry resource
    //    let mut resource_loader = ResourceLoader::singleton();
    //    if let Some(res) = resource_loader.load(res_path.clone().into()) {}

    //    Self { base, registry: () }
    //}

    fn process(&mut self, delta: f64) {
        self.registry.bind_mut().process(delta);
    }
}
