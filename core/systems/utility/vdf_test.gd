extends GutTest

const LOGIN_USERS_VDF: String = """"users"
{
	"12345678901234567"
	{
		"AccountName"        "ACCOUNT_NAME"
		"MostRecent"        "1"
		"RememberPassword"    "1"
		"PersonaName"        "PERSONA_NAME"
		"Timestamp"        "1234567890"
	}
}
"""

const LOGIN_USERS_DICT: Dictionary = {
	"users": {
		"12345678901234567": {
			"AccountName": "ACCOUNT_NAME",
			"MostRecent": "1",
			"PersonaName": "PERSONA_NAME",
			"RememberPassword": "1",
			"Timestamp": "1234567890"
		}
	}
}

const LOCAL_VDF: String = """"MachineUserConfigStore"
{
	"Software"
	{
		"valve"
		{
			"Steam"
			{
				"ConnectCache"
				{
					"1111a2222"		"someverylongtext"
				}
			}
		}
	}
}
"""

const LOCAL_DICT: Dictionary = {
	"MachineUserConfigStore": {
		"Software": {
			"valve": {
				"Steam": {
					"ConnectCache": {
						"1111a2222": "someverylongtext"
					}
				}
			}
		}
	}
}

const vdf_content: Array[String] = [LOGIN_USERS_VDF, LOCAL_VDF]
const dict_content: Array[Dictionary] = [LOGIN_USERS_DICT, LOCAL_DICT]

func test_parse() -> void:
	var i := 0
	for vdf_data in vdf_content:
		var vdf := Vdf.new()
		var err := vdf.parse(vdf_data)
		assert_eq(err, OK, "should successfully parse")
		gut.p("Got result: " + str(vdf.data))
		assert_eq(vdf.data, dict_content[i], "should deserialize the correct values")
		i += 1


func test_stringify() -> void:
	var i := 0
	for dict_data in dict_content:
		var text := Vdf.stringify(dict_data)
		gut.p("Got serialized result:\n" + text)
		assert_false(text.is_empty(), "should serialize into text")
		i += 1
