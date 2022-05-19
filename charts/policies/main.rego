package system

import data.kubernetes.admission

numberify(potential_num_str) = res {
	res := to_number(potential_num_str)
}

numberify(potential_num_str) = res {
	not to_number(potential_num_str)
	res := potential_num_str
}

numberify_path(str_array) = path {
	path := [s | s := numberify(str_array[i])]
}

# Used for determine_field_type
nums_str := {
	"0", "1", "2", "3",
	"4", "5", "6",
	"7", "8", "9",
}

patch[p] {
	data.kubernetes.admission.patch[p]
}

deny[msg] {
	data.kubernetes.admission.deny[msg]
}

# returns "array" if it's an array that needs to be created,
# "string" if it's a string that needs to be created and
# "null" if the path to be created is an array element index
# e.g. /spec/containers/0 <- don't want to make this
determine_field_type(path) = field_type {
	endswith(path, "-")
	path_array := split(path, "/")
	last_el := path_array[count(path_array) - 2]
	not nums_str[last_el]
	field_type := "array"
}

determine_field_type(path) = field_type {
	not endswith(path, "-")
	path_array := split(path, "/")
	last_el := path_array[count(path_array) - 2]
	not nums_str[last_el]
	field_type := "string"
}

determine_field_type(path) = field_type {
	not endswith(path, "-")
	path_array := split(path, "/")
	last_el := path_array[count(path_array) - 2]
	nums_str[last_el]
	field_type := "null"
}

make_path(path_array, path_type) = result {
	# Need a slice of the path_array with all but the last element.
	#   No way to do that with arrays, but we can do it with strings.
	trace(sprintf("[path_type] path_type = %s", [path_type]))
	path_type == "array"
	path_str := concat("/", array.concat([""], path_array))
	trace(sprintf("[make_path] path_array = %s", [path_array]))
	trace(sprintf("[make_path] path_str = %s", [path_str]))

	result = {
		"op": "add",
		"path": path_str,
		"value": [],
	}

	trace(sprintf("[make_path] result %s", [result]))
}

make_path(path_array, path_type) = result {
	# Need a slice of the path_array with all but the last element.
	#   No way to do that with arrays, but we can do it with strings.
	trace(sprintf("[path_type] path_type = %s", [path_type]))
	path_type == "string"
	path_str := concat("/", array.concat([""], path_array))
	trace(sprintf("[make_path] path_array = %s", [path_array]))
	trace(sprintf("[make_path] path_str = %s", [path_str]))

	result = {
		"op": "add",
		"path": path_str,
		"value": "",
	}

	trace(sprintf("[make_path] result %s", [result]))
}

ensure_parent_paths_exist(patches) = result {
	paths := {p.path | p := patches[_]}
	newpatches := {make_path(prefix_array, field_type) |
		paths[path]

		# is the path to be created an array or a string?
		field_type := determine_field_type(path)
		trace(sprintf("%s %s", [field_type, path]))
		full_length := count(path)
		path_array := split(path, "/")
		last_element_length := count(path_array[count(path_array) - 1])

		# this assumes paths starts with '/'
		prefix_path := substring(path, 1, (full_length - last_element_length) - 2)
		trace(sprintf("[ensure_parent_paths_exist] prefix_path = %s", [prefix_path]))
		prefix_array := split(prefix_path, "/")
		prefix_array_numberified := numberify_path(prefix_array)
		trace(sprintf("[ensure_parent_paths_exist] prefix_array = %s", [prefix_array_numberified]))
		not input_path_exists(prefix_array_numberified) with input as input.request.object
	}

	result := array.concat(cast_array(newpatches), patches)
}

# Check that the given @path exists as part of the input object.
input_path_exists(path) {
	trace(sprintf("[input_path_exists] input = %s", [input]))
	trace(sprintf("[input_path_exists] path = %s", [path]))
	walk(input, [path, walkval])
	trace(sprintf("[input_path_exists] walk = %s", [walkval]))
	walk(input, [path, _])
}


default response = {"allowed": true}

# non-patch response i.e. validation response
response = x {
	count(deny) > 0
	reason = concat(", ", deny)
	reason != ""

	x := {
		"allowed": false,
		"status": {"reason": reason},
	}
}

response = x {
	count(patch) > 0
	count(deny) == 0

	patches := [p | p := patch[_][_]]
	x := {
		"allowed": true,
		"patchType": "JSONPatch",
		"patch": base64.encode(json.marshal(ensure_parent_paths_exist(patches))),
	}
}

main = {
	"apiVersion": "admission.k8s.io/v1beta1",
	"kind": "AdmissionReview",
	"response": response,
}

######################### TESTS #########################

test_input_path_exists {
	input_path_exists(["spec", "containers", 0, "env"]) with input as {
		"spec": {
			"containers": [
				{
					"env": [
						{
							"name": "myenv",
							"value": "myvalue"
						}
					]
				}
			]
		}
	}

	trace(sprintf("%s", ["here"]))
}

# test_main {
# 	x := main with input.request as {
# 		"object": {
# 			"metadata": {
# 				"namespace": "yuwei",
# 				"labels": {
# 					"dsmlp/resource-type": "datascience",
# 					"dsmlp/user": "yuwei"
# 				}
# 			},
# 			"spec": {
# 				"containers": [
# 					{
# 						"env": [
# 							{
# 								"name": "myname",
# 								"value": "myvalue"
# 							}
# 						]
# 					}
# 				]
# 			}
# 		}
# 	}
# 	trace(sprintf("%s", [base64.decode(x.response.patch)]))
# 	false == true
# }
# test_deny {
# 	x := count(deny) with input.request as {
#         "object": {
#             "metadata": {
#                 "namespace": "dhub19",
#                 "labels": {
#                     "dsmlp/course": "fa-jupytere",
#                     "dsmlp/user": "dhub19"
#                 }
#             },
#             "spec": {
#                 "securityContext": {
#                     "runAsUser": 81172
#                 }
#             }
#         }
#     }
# 	trace(sprintf("%s", [x]))
# 	false
# }
# test_make_path {
# 	path_a := ["/", "res"]
# 	{
# 		"op": "add",
# 		"path": "///res",
# 		"value": "",
# 	} == make_path(path_a)
# 	path_b := ["/", "res", "-"]
# 	{
# 		"op": "add",
# 		"path": "///res/-",
# 		"value": [],
# 	} == make_path(path_b)
# }
# test_ensure_parent_paths_exist {
# 	patches := [
# 		{
# 			"op": "add",
#     		"path": "/spec/containers/0/workingDir",
#     		"value": "/home/yuwei"
# 		}
# 	]
# 	ensure_parent_paths_exist(patches) with input.request as {
#             "object": {
#                 "metadata": {
#                     "labels": {
#                         "dsmlp/user": "dhub19",
#                         "dsmlp/team": "10000"
#                     },
#                     "namespace": "dhub19"
#                 },
#                 "spec": {
#                     "containers": {
#                         "name": "test",
#                         "image": "fakeimg:faketag"
#                     },
#                 }
#             }
#         }
# 	false
# }
