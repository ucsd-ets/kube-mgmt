package kubernetes.admission

limits_cpu := input.request.object.spec.containers[0].resources.limits.cpu

limits_memory := input.request.object.spec.containers[0].resources.limits.memory

requests_cpu := input.request.object.spec.containers[0].resources.requests.cpu

requests_memory := input.requests.object.spec.containers[0].resources.requests.memory

image := input.request.object.spec.containers[0].image

scipy_ml_image_name := "ucsdets/scipy-ml-notebook:2022.1-stable"
datascience_image_name := "ucsdets/datascience-notebook:2022.1-stable"

get_add_image_patch(image_name) = patch {
	patch := {
		"op": "add",
		"path": "/spec/containers/0/image",
		"value": image_name
	}
}

low_resources := {
	"op": "add",
	"path": "/spec/containers/0/resources",
	"value": {
		"requests": {
			"cpu": 0.5,
			"memory": "2G",
		},
		"limits": {
			"cpu": 2,
			"memory": "4G",
		},
	},
}

high_resources := {
	"op": "add",
	"path": "/spec/containers/0/resources",
	"value": {
		"requests": {
			"cpu": 4,
			"memory": "8G",
		},
		"limits": {
			"cpu": 8,
			"memory": "16G",
		},
	},
}

high_resources_with_gpu := {
	"op": "add",
	"path": "/spec/containers/0/resources",
	"value": {
		"requests": {
			"cpu": 4,
			"memory": "8G",
			"nvidia.com/gpu": 1,
		},
		"limits": {
			"cpu": 8,
			"memory": "16G",
			"nvidia.com/gpu": 1,
		},
	},
}



jupyter_image_spec_envar := {
	"op": add_or_replace_array_elem(input.spec.containers[0].env[_].name, "JUPYTER_IMAGE_SPEC"),
	"path": "/spec/containers/0/env",
	"value": {
		"name": "JUPYTER_IMAGE_SPEC",
		"value": image
	}
}

# get_jupyter_image_spec_envar_patch(image_name) = jupyter_image_patch {
# 	varname = "JUPYTER_IMAGE_SPEC"
# 	trace("HERE\n\n\n")
# 	op := add_or_replace_array_elem(input.spec.containers[0].env, varname)
# 	jupyter_image_patch := {
# 		"op": op,
# 		"path": "/spec/containers/0/env",
# 		"value": {
# 			"name": varname,
# 			"value": image_name
# 		}
# 	}
# }

patch[p] {
	resource_type == "scipy-ml-low"
	p = replace_protect_patches([
		low_resources,
		get_add_image_patch(scipy_ml_image_name),
	])
}

patch[p] {
	resource_type == "scipy-ml-high"
	p = replace_protect_patches([
		high_resources_with_gpu,
		get_add_image_patch(scipy_ml_image_name),
	])
}

patch[p] {
	resource_type == "datascience"
	p := replace_protect_patches([
		low_resources,
		get_add_image_patch(datascience_image_name),
	])
}

######################### TESTS #########################

test_resources_get_added_upon_resource_type_datascience {
	patch[[
		low_resources,
		datascience_image,
	]] with input.request as {"object": {
		"metadata": {
			"labels": {
				"dsmlp/user": "dhub19",
				"dsmlp/team": "10000",
				"dsmlp/resource-type": "datascience",
			},
			"namespace": "dhub19",
		},
		"spec": {"containers": [{"name": "test"}]},
	}}
}

test_resources_dont_get_added_without_datascience {
	p := patch with input.request as {"object": {
		"metadata": {
			"labels": {},
			"namespace": "dhub19",
		},
		"spec": {"containers": [{
			"name": "test",
			"image": "fakeimg:faketag",
		}]},
	}}

	s := {p | p := patch[i]}
	count(s) == 0
}

test_scipy_ml_high {
	patch[[
		high_resources_with_gpu,
		scipy_ml_image,
	]] with input.request as {"object": {
		"metadata": {
			"labels": {"dsmlp/resource-type": "scipy-ml-high"},
			"namespace": "dhub19",
		},
		"spec": {"containers": [{"name": "test"}]}, 
	}}
}

# test_replace_gets_added {
# 	res := patch with input.request as {"object": {
# 		"metadata": {
# 			"labels": {"dsmlp/resource-type": "datascience"},
# 			"namespace": "dhub19",
# 		},
# 		"spec": {"containers": [{
# 			"name": "test",
# 			"image": "fakeimg:faketag",
# 			"resources": {"limits": {"cpu": 1}},
# 			"env": [
# 				{
# 					"name": "JUPYTER_IMAGE_SPEC",
# 					"value": "myvalue"
# 				}
# 			]
# 		}]},
# 	}}
# 	trace(sprintf("%s", [res]))
# 	true == false
# }
