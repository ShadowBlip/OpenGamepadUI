use godot::{classes::ResourceLoader, prelude::*};

/// Path to the main [ResourceRegistry] instance
const RESOURCE_REGISTRY: &str = "res://core/systems/resource/resource_registry.tres";

/// Class for registering [Resource] objects with a [method process] method that will get executed every frame by a [ResourceProcessor].
///
/// By design, [Resource] objects do not have access to the scene tree in order to be updated every frame during the [method process] loop. The [ResourceRegistry] provides a way for [Resource] objects to register themselves to have their [method process] method called every frame by a [ResourceProcessor] node.
///
/// By saving the [ResourceRegistry] as a `.tres` file, [Resource] objects anywhere in the project can load the same [ResourceRegistry] instance and register themselves to run their [method process] method every frame by a [ResourceProcessor] node in the scene tree.
///
/// Example
///
/// [codeblock]
/// var registry := load("res://path/to/registry.tres") as ResourceRegistry
/// registry.register(self)
/// [/codeblock]
#[derive(GodotClass)]
#[class(init, base=Resource)]
pub struct ResourceRegistry {
    base: Base<Resource>,
    resources: Array<Gd<RefCounted>>,
    child_nodes: Array<Gd<Node>>,
}

#[godot_api]
impl ResourceRegistry {
    #[signal]
    fn child_added(child: Gd<Node>);
    #[signal]
    fn child_removed(child: Gd<Node>);

    /// Gets the main [ResourceRegistry] instance
    #[func]
    pub fn get_registry() -> Option<Gd<Self>> {
        let mut resource_loader = ResourceLoader::singleton();
        let resource = resource_loader.load(RESOURCE_REGISTRY)?;
        let registry: Gd<Self> = resource.cast();
        Some(registry)
    }

    /// Register the given resource with the registry. The given resource will have its [method process] method called every frame by a [ResourceProcessor] in the scene tree.
    #[func]
    pub fn register(&mut self, resource: Gd<RefCounted>) {
        log::trace!("Registering resource: {resource}");
        if !resource.has_method("process") {
            log::error!(
                "Tried to register resource for processing, but resource has no process method: {resource}"
            );
            return;
        }
        if self.resources.contains(&resource) {
            log::trace!("Resource already registered: {resource}");
            return;
        }
        self.resources.push(&resource);
        log::trace!("Registered resources: {}", self.resources);
    }

    /// Unregister the given resource from the registry.
    #[func]
    pub fn unregister(&mut self, resource: Gd<RefCounted>) {
        log::trace!("Unregistering resource: {resource}");
        if !self.resources.contains(&resource) {
            log::warn!("Resource is not registered: {resource}");
            return;
        }
        self.resources.erase(&resource);
        log::trace!("Registered resources: {}", self.resources);
    }

    /// Calls the `process()` method on all registered [Resource] objects. This should be called from a [Node] in the scene tree like the [ResourceProcessor].
    #[func]
    pub fn process(&mut self, delta: f64) {
        // Call process on each registered resource
        for mut resource in self.resources.iter_shared() {
            resource.call("process", &[delta.to_variant()]);
        }
    }

    /// Adds the given node to the [ResourceProcessor] node associated with this registry. This provides a way for resources to add nodes into the scene tree.
    #[func]
    pub fn add_child(&mut self, child: Gd<Node>) {
        self.child_nodes.push(&child);
        self.base_mut()
            .emit_signal("child_added", &[child.to_variant()]);
    }

    /// Removes the given node from the scene tree
    #[func]
    pub fn remove_child(&mut self, child: Gd<Node>) {
        self.child_nodes.erase(&child);
        self.base_mut()
            .emit_signal("child_removed", &[child.to_variant()]);
    }

    /// Returns a list of all nodes that should be added as children to a [ResourceProcessor]
    #[func]
    pub fn get_children(&self) -> Array<Gd<Node>> {
        self.child_nodes.clone()
    }
}
