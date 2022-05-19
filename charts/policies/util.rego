package kubernetes.admission

awsed_url = opa.runtime().env.AWSED_URL {
	opa.runtime().env.AWSED_URL
}

else = input.env.awsedEndpoint {
	true
}

apikey = opa.runtime().env.AWSED_API_KEY {
	opa.runtime().env.AWSED_API_KEY
}

else = input.env.awsedApiKey {
	true
}

replace_patch := {"op": "replace", "path": "/op", "value": "replace"}

headers := {"Authorization": apikey}

fetch_course(course) = coursejson {
	url := sprintf("%s/api/courses/%s", [awsed_url, course])
	coursejson := http.send({
		"method": "GET",
		"url": url,
		"headers": headers,
		"raise_error": false,
	}).body
}

fetch_user_courses(username) = courseinfo {
	url := sprintf("%s/api/enrollments?username=%s", [awsed_url, username])
	courseinfo := http.send({
		"method": "GET",
		"url": url,
		"headers": headers,
		"raise_error": false,
	})
}

fetch_user_info(username) = userinfo {
	url := sprintf("%s/api/users/%s", [awsed_url, username])
	userinfo := http.send({
		"method": "GET",
		"url": url,
		"headers": headers,
		"raise_error": false,
	})
}

fetch_uid(username) = uid {
	userinfo = fetch_user_info(username)
	uid = userinfo.body.uid
}

fetch_user_teams(username) = teaminfo {
	url := sprintf("%s/api/teams?username=%s", [awsed_url, username])
	response = http.send({
		"method": "GET",
		"url": url,
		"headers": headers,
		"raise_error": false,
	})

	teaminfo := response.body.teams
}

fetch_team_info(username) = teaminfo {
	url := sprintf("%s/api/teams?username=%s", [awsed_url, username])
	response = http.send({
		"method": "GET",
		"url": url,
		"headers": headers,
		"raise_error": false,
	})

	teaminfo := response.body.teams
}

contains(arr, elem) {
	arr[_] = elem
}

# protect against adding a jsonpatch if it already exists. Will modify the "op": "add" to
# "op": "replace"
replace_protect(jsonpatch, path) = newobj {
	input_path_exists(path)
	newobj := json.patch(jsonpatch, [replace_patch])
}

replace_protect(jsonpatch, path) = newobj {
	not input_path_exists(path)
	newobj := jsonpatch
}

input_path_exists(path) {
	trace(sprintf("[input_path_exists] input = %s", [input]))
	trace(sprintf("[input_path_exists] path = %s", [path]))
	walk(input, [path, walkval])
	trace(sprintf("[input_path_exists] walk = %s", [walkval]))
	walk(input, [path, _])
}

add_or_replace_array_elem(arr, elem) = method {
	contains(arr, elem)
	method = "replace"
}

add_or_replace_array_elem(arr, elem) = method {
	not contains(arr, elem)
	method = "add"
}

numberify(potential_num_str) = res {
	res := to_number(potential_num_str)
}

numberify(potential_num_str) = res {
	not to_number(potential_num_str)
	res := potential_num_str
}

str_to_path(strpath) = path {
	as_arr := split(strpath, "/")
	filtered := array.slice(as_arr, 1, count(as_arr))
	path := [s | s := numberify(filtered[i])]
}

# get the kubernetes path to the object
kubernetes_pathify(strpath) = newpath {
	newpath := array.concat(["request", "object"], str_to_path(strpath))
}

replace_protect_patches(patches) = protected_patches {
	protected_patches := [p | p := replace_protect(patches[i], kubernetes_pathify(patches[i].path))]
}

# ######################### TESTS #########################

test_add_or_replace_array_elem {
	arr := ["my", "element", "is", "this"]
	val := "my"
	res := add_or_replace_array_elem(arr, val)
	res == "replace"

	val_fail := "doesnotexist"
	res_fail := add_or_replace_array_elem(arr, val_fail)
	res_fail == "add"
}

# test_get_homepath {
#     grader_working_dir := get_homepath("grader-acms123-01") with input.request as {
#         "object": {
#             "metadata": {
#                 "labels": {
#                     "dsmlp/user": "grader-acms123-01",
#                     "dsmlp/grader": "grader-acms123-01",
#                     "dsmlp/course": "ACMS123_FA21_A00"
#                 }
#             }
#         }
#     }
#     grader_working_dir == "/srv/nbgrader/ACMS123_FA21_A00"
#     user_working_dir := get_homepath("grader-acms123-01") with input.request as {
#         "object": {
#             "metadata": {
#                 "labels": {
#                     "dsmlp/user": "grader-acms123-01",
#                 }
#             }
#         }
#     }
#     user_working_dir == "/home/grader-acms123-01"
# }
# test_replace_protect {
#     # test replace
#     test_add := {
#         "op": "add",
#         "path": "/spec/test",
#         "value": 2
#     }
#     obj := replace_protect(test_add, ["spec", "test"]) with input as {
#         "spec": {
#             "test": 1
#         }
#     }
#     obj == {
#         "op": "replace",
#         "path": "/spec/test",
#         "value": 2
#     }
#     # test not replace
#     obj2 := replace_protect(test_add, ["spec", "test"]) with input as {
#         "spec": {}
#     }
#     obj2 == {
#         "op": "add",
#         "path": "/spec/test",
#         "value": 2
#     }
# }
# test_str_to_path {
#     strp := "/spec/containers/0/limits"
#     res := str_to_path(strp)
#     res == ["spec", "containers", 0, "limits"]
#     strp2 := "/spec/containers"
#     res2 := str_to_path(strp2)
#     res2 == ["spec", "containers"]
# }
# test_replace_protect_patches {
#     p := [
#         cpu_requests_datascience,
#         mem_limits_datascience
#     ]
#     res := replace_protect_patches(p) with input as {
#         "request": {
#             "object": {
#                 "spec": {
#                     "containers": [
#                         {
#                             "resources": {
#                                 "limits": {
#                                     "memory": "1G"
#                                 }
#                             }
#                         }
#                     ]
#                 }
#             }
#         }
#     }
#     res[0].op == "add"
#     res[1].op == "replace"
# }
