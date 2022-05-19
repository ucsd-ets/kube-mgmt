package kubernetes.admission

# keep container_args in order
container_args_0 := {
	"op": "add",
	"path": "/spec/containers/0/args/-",
	"value": "/opt/k8s-support/bin/tini-wrapper"
}

container_args_1 := {
	"op": "add",
	"path": "/spec/containers/0/args/-",
	"value": "--ip=0.0.0.0"
}

container_args_2 := {
	"op": "add",
	"path": "/spec/containers/0/args/-",
	"value": "--port=8888"
}


container_args_3 := {
	"op": "add",
	"path": "/spec/containers/0/args/-",
	"value": "--",
}

container_args_4 := {
	"op": "add",
	"path": "/spec/containers/0/args/-",
	"value": "/opt/k8s-support/bin/initenv-createhomedir.sh",
}

container_args_5 := {
	"op": "add",
	"path": "/spec/containers/0/args/-",
	"value": "jupyterhub-singleuser",
}

container_args_6 := {
	"op": "add",
	"path": "/spec/containers/0/args/-",
	"value": "--KernelRestarter.restart_limit=0",
}


patch[p] {
	datahub
	p := [
		container_args_0,
		container_args_1,
		container_args_2,
		container_args_3,
		container_args_4,
		container_args_5,
		container_args_6,
	]
}

######################### TESTS #########################

test_jupyter_api_url_env_patch_added {
	patch[[
		container_args_0,
		container_args_1,
		container_args_2,
		container_args_3,
		container_args_4,
		container_args_5,
		container_args_6,
	]] with input.request as {"object": {
		"metadata": {
			"labels": {
				"dsmlp/user": "dhub19",
				"dsmlp/datahub": "true",
			},
			"namespace": "dhub19",
		},
		"spec": {
			"containers": {
				"name": "test",
				"image": "fakeimg:faketag",
			},
			"securityContext": {"runAsUser": 81172},
		},
	}}
}
