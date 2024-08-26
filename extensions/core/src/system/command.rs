use std::sync::mpsc::Receiver;

use godot::prelude::*;

//// Signals that can be emitted
//#[derive(Debug)]
//enum Signal {
//    InputEvent {
//        type_code: String,
//        value: f64,
//    },
//    TouchEvent {
//        type_code: String,
//        index: u32,
//        is_touching: bool,
//        pressure: f64,
//        x: f64,
//        y: f64,
//    },
//}
//
//#[derive(GodotClass)]
//#[class(base=RefCounted)]
//pub struct Command {
//    base: Base<RefCounted>,
//    path: String,
//    rx: Receiver<Signal>,
//}
//
//#[godot_api]
//impl Command {
//    #[signal]
//    fn input_event(type_code: GString, value: f64);
//
//    #[signal]
//    fn touch_event(
//        type_code: GString,
//        index: i64,
//        is_touching: bool,
//        pressure: f64,
//        x: f64,
//        y: f64,
//    );
//}
