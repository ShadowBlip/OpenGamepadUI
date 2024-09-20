use godot::prelude::*;

#[derive(GodotClass)]
#[class(init, base=Resource)]
pub struct ResourceRegistry {
    base: Base<Resource>,
    resources: Array<Gd<Resource>>,
}

#[godot_api]
impl ResourceRegistry {
    /// Register the given resource with the registry. The given resource will have its "process()" method called every frame by a [ResourceProcessor].
    pub fn register(&mut self, resource: Gd<Resource>) {
        if !resource.has_method("process".into()) {
            godot_error!(
                "Tried to register resource for processing, but resource has no process method: {resource}"
            );
            return;
        }
        if self.resources.contains(&resource) {
            return;
        }
        self.resources.push(resource);
    }

    /// Unregister the given resource from the registry.
    pub fn unregister(&mut self, resource: Gd<Resource>) {
        self.resources.erase(&resource);
    }

    /// Calls the "process()" method on all registered resources. This should be called from a [Node] in the scene tree like the [ResourceProcessor].
    pub fn process(&mut self, delta: f64) {
        for mut resource in self.resources.iter_shared() {
            resource.call("process".into(), &[delta.to_variant()]);
        }
    }
}
