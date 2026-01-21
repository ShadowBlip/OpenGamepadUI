# GutTest

**Inherits:** [Node](https://docs.godotengine.org/en/stable/classes/class_node.html)


## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [gut](./#gut) | null |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [DOUBLE_STRATEGY](./#DOUBLE_STRATEGY) | {"INCLUDE_NATIVE": 0, "SCRIPT_ONLY": 1} |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [ParameterFactory](./#ParameterFactory) | <unknown> |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [CompareResult](./#CompareResult) | <unknown> |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [InputFactory](./#InputFactory) | <unknown> |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [InputSender](./#InputSender) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| void | [before_all](./#before_all)() |
| void | [before_each](./#before_each)() |
| void | [after_all](./#after_all)() |
| void | [after_each](./#after_each)() |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [get_logger](./#get_logger)() |
| void | [set_logger](./#set_logger)(logger: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html)) |
| void | [assert_eq](./#assert_eq)(got: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), expected: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "") |
| void | [assert_ne](./#assert_ne)(got: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), not_expected: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "") |
| void | [assert_almost_eq](./#assert_almost_eq)(got: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), expected: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), error_interval: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "") |
| void | [assert_almost_ne](./#assert_almost_ne)(got: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), not_expected: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), error_interval: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "") |
| void | [assert_gt](./#assert_gt)(got: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), expected: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "") |
| void | [assert_lt](./#assert_lt)(got: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), expected: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "") |
| void | [assert_true](./#assert_true)(got: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "") |
| void | [assert_false](./#assert_false)(got: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "") |
| void | [assert_between](./#assert_between)(got: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), expect_low: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), expect_high: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "") |
| void | [assert_not_between](./#assert_not_between)(got: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), expect_low: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), expect_high: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "") |
| void | [assert_has](./#assert_has)(obj: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), element: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "") |
| void | [assert_does_not_have](./#assert_does_not_have)(obj: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), element: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "") |
| void | [assert_file_exists](./#assert_file_exists)(file_path: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html)) |
| void | [assert_file_does_not_exist](./#assert_file_does_not_exist)(file_path: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html)) |
| void | [assert_file_empty](./#assert_file_empty)(file_path: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html)) |
| void | [assert_file_not_empty](./#assert_file_not_empty)(file_path: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html)) |
| void | [assert_has_method](./#assert_has_method)(obj: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), method: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "") |
| void | [assert_accessors](./#assert_accessors)(obj: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), property: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), default: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), set_to: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html)) |
| void | [assert_exports](./#assert_exports)(obj: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), property_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), type: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html)) |
| void | [watch_signals](./#watch_signals)(object: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html)) |
| void | [assert_connected](./#assert_connected)(signaler_obj: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), connect_to_obj: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), signal_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), method_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "") |
| void | [assert_not_connected](./#assert_not_connected)(signaler_obj: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), connect_to_obj: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), signal_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), method_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "") |
| void | [assert_signal_emitted](./#assert_signal_emitted)(object: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), signal_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "") |
| void | [assert_signal_not_emitted](./#assert_signal_not_emitted)(object: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), signal_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "") |
| void | [assert_signal_emitted_with_parameters](./#assert_signal_emitted_with_parameters)(object: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), signal_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), parameters: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), index: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = -1) |
| void | [assert_signal_emit_count](./#assert_signal_emit_count)(object: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), signal_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), times: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "") |
| void | [assert_has_signal](./#assert_has_signal)(object: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), signal_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "") |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [get_signal_emit_count](./#get_signal_emit_count)(object: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), signal_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html)) |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [get_signal_parameters](./#get_signal_parameters)(object: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), signal_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), index: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = -1) |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [get_call_parameters](./#get_call_parameters)(object: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), method_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), index: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = -1) |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [get_call_count](./#get_call_count)(object: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), method_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), parameters: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null) |
| void | [assert_is](./#assert_is)(object: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), a_class: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "") |
| void | [assert_typeof](./#assert_typeof)(object: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), type: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "") |
| void | [assert_not_typeof](./#assert_not_typeof)(object: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), type: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "") |
| void | [assert_string_contains](./#assert_string_contains)(text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), search: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), match_case: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = true) |
| void | [assert_string_starts_with](./#assert_string_starts_with)(text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), search: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), match_case: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = true) |
| void | [assert_string_ends_with](./#assert_string_ends_with)(text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), search: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), match_case: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = true) |
| void | [assert_called](./#assert_called)(inst: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), method_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), parameters: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null) |
| void | [assert_not_called](./#assert_not_called)(inst: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), method_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), parameters: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null) |
| void | [assert_call_count](./#assert_call_count)(inst: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), method_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), expected_count: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), parameters: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null) |
| void | [assert_null](./#assert_null)(got: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "") |
| void | [assert_not_null](./#assert_not_null)(got: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "") |
| void | [assert_freed](./#assert_freed)(obj: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), title: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "something") |
| void | [assert_not_freed](./#assert_not_freed)(obj: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), title: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html)) |
| void | [assert_no_new_orphans](./#assert_no_new_orphans)(text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "") |
| void | [assert_setget](./#assert_setget)(instance: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), name_property: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), const_or_setter: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null, getter: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "__not_set__") |
| void | [assert_set_property](./#assert_set_property)(obj: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), property_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), new_value: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), expected_value: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html)) |
| void | [assert_readonly_property](./#assert_readonly_property)(obj: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), property_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), new_value: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), expected_value: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html)) |
| void | [assert_property_with_backing_variable](./#assert_property_with_backing_variable)(obj: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), property_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), default_value: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), new_value: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), backed_by_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null) |
| void | [assert_property](./#assert_property)(obj: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), property_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), default_value: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), new_value: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html)) |
| void | [pending](./#pending)(text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "") |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [wait_seconds](./#wait_seconds)(time: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), msg: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "") |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [yield_for](./#yield_for)(time: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), msg: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "") |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [wait_for_signal](./#wait_for_signal)(sig: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), max_wait: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), msg: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "") |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [yield_to](./#yield_to)(obj: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), signal_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), max_wait: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), msg: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "") |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [wait_frames](./#wait_frames)(frames: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), msg: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "") |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [yield_frames](./#yield_frames)(frames: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), msg: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "") |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [get_summary](./#get_summary)() |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [get_fail_count](./#get_fail_count)() |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [get_pass_count](./#get_pass_count)() |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [get_pending_count](./#get_pending_count)() |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [get_assert_count](./#get_assert_count)() |
| void | [clear_signal_watcher](./#clear_signal_watcher)() |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [get_double_strategy](./#get_double_strategy)() |
| void | [set_double_strategy](./#set_double_strategy)(double_strategy: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html)) |
| void | [pause_before_teardown](./#pause_before_teardown)() |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [get_summary_text](./#get_summary_text)() |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [double](./#double)(thing: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), double_strat: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null, not_used_anymore: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null) |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [partial_double](./#partial_double)(thing: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), double_strat: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null, not_used_anymore: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null) |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [double_singleton](./#double_singleton)(singleton_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html)) |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [partial_double_singleton](./#partial_double_singleton)(singleton_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html)) |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [double_scene](./#double_scene)(path: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), strategy: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null) |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [double_script](./#double_script)(path: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), strategy: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null) |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [double_inner](./#double_inner)(path: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), subpath: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), strategy: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null) |
| void | [ignore_method_when_doubling](./#ignore_method_when_doubling)(thing: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), method_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html)) |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [stub](./#stub)(thing: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), p2: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), p3: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null) |
| void | [simulate](./#simulate)(obj: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), times: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), delta: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), check_is_processing: [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) = false) |
| void | [replace_node](./#replace_node)(base_node: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), path_or_node: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), with_this: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html)) |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [use_parameters](./#use_parameters)(params: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html)) |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [autofree](./#autofree)(thing: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html)) |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [autoqfree](./#autoqfree)(thing: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html)) |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [add_child_autofree](./#add_child_autofree)(node: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), legible_unique_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = false) |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [add_child_autoqfree](./#add_child_autoqfree)(node: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), legible_unique_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = false) |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [is_passing](./#is_passing)() |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [is_failing](./#is_failing)() |
| void | [pass_test](./#pass_test)(text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html)) |
| void | [fail_test](./#fail_test)(text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html)) |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [compare_deep](./#compare_deep)(v1: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), v2: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), max_differences: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null) |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [compare_shallow](./#compare_shallow)(v1: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), v2: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), max_differences: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null) |
| void | [assert_eq_deep](./#assert_eq_deep)(v1: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), v2: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html)) |
| void | [assert_ne_deep](./#assert_ne_deep)(v1: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), v2: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html)) |
| void | [assert_eq_shallow](./#assert_eq_shallow)(v1: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), v2: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html)) |
| void | [assert_ne_shallow](./#assert_ne_shallow)(v1: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), v2: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html)) |
| void | [assert_same](./#assert_same)(v1: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), v2: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "") |
| void | [assert_not_same](./#assert_not_same)(v1: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), v2: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "") |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [skip_if_godot_version_lt](./#skip_if_godot_version_lt)(expected: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html)) |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [skip_if_godot_version_ne](./#skip_if_godot_version_ne)(expected: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html)) |
| void | [register_inner_classes](./#register_inner_classes)(base_script: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html)) |


------------------

## Property Descriptions

### `gut`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) gut = <span style="color: red;">null</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `DOUBLE_STRATEGY`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) DOUBLE_STRATEGY = <span style="color: red;">{"INCLUDE_NATIVE": 0, "SCRIPT_ONLY": 1}</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `ParameterFactory`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) ParameterFactory


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `CompareResult`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) CompareResult


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `InputFactory`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) InputFactory


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `InputSender`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) InputSender


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `before_all()`


void **before_all**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `before_each()`


void **before_each**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `after_all()`


void **after_all**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `after_each()`


void **after_each**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_logger()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **get_logger**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `set_logger()`


void **set_logger**(logger: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_eq()`


void **assert_eq**(got: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), expected: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_ne()`


void **assert_ne**(got: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), not_expected: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_almost_eq()`


void **assert_almost_eq**(got: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), expected: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), error_interval: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_almost_ne()`


void **assert_almost_ne**(got: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), not_expected: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), error_interval: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_gt()`


void **assert_gt**(got: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), expected: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_lt()`


void **assert_lt**(got: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), expected: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_true()`


void **assert_true**(got: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_false()`


void **assert_false**(got: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_between()`


void **assert_between**(got: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), expect_low: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), expect_high: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_not_between()`


void **assert_not_between**(got: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), expect_low: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), expect_high: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_has()`


void **assert_has**(obj: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), element: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_does_not_have()`


void **assert_does_not_have**(obj: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), element: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_file_exists()`


void **assert_file_exists**(file_path: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_file_does_not_exist()`


void **assert_file_does_not_exist**(file_path: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_file_empty()`


void **assert_file_empty**(file_path: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_file_not_empty()`


void **assert_file_not_empty**(file_path: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_has_method()`


void **assert_has_method**(obj: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), method: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_accessors()`


void **assert_accessors**(obj: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), property: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), default: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), set_to: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_exports()`


void **assert_exports**(obj: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), property_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), type: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `watch_signals()`


void **watch_signals**(object: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_connected()`


void **assert_connected**(signaler_obj: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), connect_to_obj: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), signal_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), method_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_not_connected()`


void **assert_not_connected**(signaler_obj: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), connect_to_obj: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), signal_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), method_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_signal_emitted()`


void **assert_signal_emitted**(object: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), signal_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_signal_not_emitted()`


void **assert_signal_not_emitted**(object: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), signal_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_signal_emitted_with_parameters()`


void **assert_signal_emitted_with_parameters**(object: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), signal_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), parameters: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), index: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = -1)


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_signal_emit_count()`


void **assert_signal_emit_count**(object: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), signal_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), times: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_has_signal()`


void **assert_has_signal**(object: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), signal_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_signal_emit_count()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **get_signal_emit_count**(object: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), signal_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_signal_parameters()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **get_signal_parameters**(object: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), signal_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), index: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = -1)


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_call_parameters()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **get_call_parameters**(object: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), method_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), index: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = -1)


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_call_count()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **get_call_count**(object: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), method_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), parameters: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null)


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_is()`


void **assert_is**(object: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), a_class: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_typeof()`


void **assert_typeof**(object: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), type: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_not_typeof()`


void **assert_not_typeof**(object: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), type: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_string_contains()`


void **assert_string_contains**(text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), search: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), match_case: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = true)


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_string_starts_with()`


void **assert_string_starts_with**(text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), search: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), match_case: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = true)


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_string_ends_with()`


void **assert_string_ends_with**(text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), search: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), match_case: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = true)


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_called()`


void **assert_called**(inst: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), method_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), parameters: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null)


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_not_called()`


void **assert_not_called**(inst: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), method_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), parameters: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null)


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_call_count()`


void **assert_call_count**(inst: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), method_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), expected_count: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), parameters: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null)


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_null()`


void **assert_null**(got: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_not_null()`


void **assert_not_null**(got: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_freed()`


void **assert_freed**(obj: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), title: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "something")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_not_freed()`


void **assert_not_freed**(obj: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), title: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_no_new_orphans()`


void **assert_no_new_orphans**(text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_setget()`


void **assert_setget**(instance: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), name_property: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), const_or_setter: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null, getter: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "__not_set__")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_set_property()`


void **assert_set_property**(obj: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), property_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), new_value: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), expected_value: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_readonly_property()`


void **assert_readonly_property**(obj: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), property_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), new_value: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), expected_value: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_property_with_backing_variable()`


void **assert_property_with_backing_variable**(obj: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), property_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), default_value: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), new_value: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), backed_by_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null)


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_property()`


void **assert_property**(obj: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), property_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), default_value: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), new_value: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `pending()`


void **pending**(text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `wait_seconds()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **wait_seconds**(time: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), msg: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `yield_for()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **yield_for**(time: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), msg: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `wait_for_signal()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **wait_for_signal**(sig: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), max_wait: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), msg: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `yield_to()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **yield_to**(obj: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), signal_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), max_wait: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), msg: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `wait_frames()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **wait_frames**(frames: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), msg: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `yield_frames()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **yield_frames**(frames: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), msg: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_summary()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **get_summary**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_fail_count()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **get_fail_count**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_pass_count()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **get_pass_count**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_pending_count()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **get_pending_count**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_assert_count()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **get_assert_count**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `clear_signal_watcher()`


void **clear_signal_watcher**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_double_strategy()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **get_double_strategy**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `set_double_strategy()`


void **set_double_strategy**(double_strategy: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `pause_before_teardown()`


void **pause_before_teardown**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_summary_text()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **get_summary_text**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `double()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **double**(thing: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), double_strat: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null, not_used_anymore: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null)


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `partial_double()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **partial_double**(thing: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), double_strat: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null, not_used_anymore: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null)


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `double_singleton()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **double_singleton**(singleton_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `partial_double_singleton()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **partial_double_singleton**(singleton_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `double_scene()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **double_scene**(path: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), strategy: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null)


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `double_script()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **double_script**(path: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), strategy: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null)


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `double_inner()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **double_inner**(path: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), subpath: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), strategy: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null)


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `ignore_method_when_doubling()`


void **ignore_method_when_doubling**(thing: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), method_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `stub()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **stub**(thing: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), p2: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), p3: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null)


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `simulate()`


void **simulate**(obj: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), times: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), delta: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), check_is_processing: [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) = false)


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `replace_node()`


void **replace_node**(base_node: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), path_or_node: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), with_this: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `use_parameters()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **use_parameters**(params: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `autofree()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **autofree**(thing: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `autoqfree()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **autoqfree**(thing: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `add_child_autofree()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **add_child_autofree**(node: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), legible_unique_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = false)


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `add_child_autoqfree()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **add_child_autoqfree**(node: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), legible_unique_name: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = false)


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `is_passing()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **is_passing**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `is_failing()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **is_failing**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `pass_test()`


void **pass_test**(text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `fail_test()`


void **fail_test**(text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `compare_deep()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **compare_deep**(v1: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), v2: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), max_differences: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null)


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `compare_shallow()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **compare_shallow**(v1: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), v2: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), max_differences: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null)


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_eq_deep()`


void **assert_eq_deep**(v1: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), v2: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_ne_deep()`


void **assert_ne_deep**(v1: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), v2: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_eq_shallow()`


void **assert_eq_shallow**(v1: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), v2: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_ne_shallow()`


void **assert_ne_shallow**(v1: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), v2: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_same()`


void **assert_same**(v1: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), v2: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `assert_not_same()`


void **assert_not_same**(v1: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), v2: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), text: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = "")


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `skip_if_godot_version_lt()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **skip_if_godot_version_lt**(expected: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `skip_if_godot_version_ne()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **skip_if_godot_version_ne**(expected: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `register_inner_classes()`


void **register_inner_classes**(base_script: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

