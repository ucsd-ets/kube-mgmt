package kubernetes.admission


k8s_support_volumemount := {
	"name": "support",
	"mountPath": "/opt/k8s-support",
}

k8s_support_init_container := {
	"op": "add",
	"path": "/spec/initContainers/-",
	"value": {
		"name": "init-support",
		"image": "ucsdets/k8s-support:2019.4-stable",
		"command": ["/bin/sh", "-c"],
		"args": ["cp -r /support/* /opt/k8s-support ; ls -al /opt/k8s-support"],
		"volumeMounts": [{
			"mountPath": "/opt/k8s-support",
			"name": "support",
		}],
		"resources": {
			"limits": {
				"cpu": 0.5,
				"memory": "256M",
			},
			"requests": {
				"cpu": 0.5,
				"memory": "256M",
			},
		},
	},
}

k8s_support_vol := {
	"op": "add",
	"path": "/spec/volumes/-",
	"value": {
		"name": "support",
		"emptyDir": {},
	},
}

k8s_support_containers_volumemount := {
	"op": "add",
	"path": "/spec/containers/0/volumeMounts/-",
	"value": k8s_support_volumemount,
}


termination_grace_period_seconds := {
	"op": "add",
	"path": "/spec/terminationGracePeriodSeconds",
	"value": 600,
}

log_name_envar := {
	"op": "add",
	"path": "/spec/containers/0/env/-",
	"value": {
		"name": "LOGNAME",
		"value": username
	}
}

nb_umask_envar := {
	"op": "add",
	"path": "/spec/containers/0/env/-",
	"value": {
		"name": "NB_UMASK",
		"value": "0007",
	},
}

working_dir := {
	"op": "add",
	"path": "/spec/containers/0/workingDir",
	"value": get_homepath(username),
}

datasets_volume := {
	"op": "add",
	"path": "/spec/volumes/-",
	"value": {
		"name": "dsmlp-datasets",
		"persistentVolumeClaim": {"claimName": "dsmlp-datasets"},
	},
}

datasets_volumemount := {
	"op": "add",
	"path": "/spec/containers/0/volumeMounts/-",
	"value": {
		"name": "dsmlp-datasets",
		"mountPath": "/datasets",
	},
}

dhsm_volume := {
	"op": "add",
	"path": "/spec/volumes/-",
	"value": {
		"name": "dshm",
		"emptyDir": {},
	},
}

dhsm_volumemount := {
	"op": "add",
	"path": "/spec/containers/0/volumeMounts/-",
	"value": {
		"name": "dshm",
		"mountPath": "/dev/dshm",
	},
}

nbmessages_volume := {
	"op": "add",
	"path": "/spec/volumes/-",
	"value": {
		"name": "nbmessages",
		"nfs": {
			"path": "/export/nbmessages",
			"server": "its-dsmlp-fs01.ucsd.edu",
		},
	},
}

nbmessages_volumemount := {
	"op": "add",
	"path": "/spec/containers/0/volumeMounts/-",
	"value": {
		"name": "nbmessages",
		"mountPath": "/srv/nbmessages",
	},
}

datasets_2_volume := {
	"op": "add",
	"path": "/spec/volumes/-",
	"value": {
		"name": "dsmlp-datasets-2",
		"nfs": {
			"path": "/export/datasets",
			"server": "its-dsmlp-fs02.ucsd.edu",
		},
	},
}

datasets_2_volumemount := {
	"op": "add",
	"path": "/spec/containers/0/volumeMounts/-",
	"value": {
		"name": "dsmlp-datasets-2",
		"mountPath": "/datasets-2",
	},
}

patch[p] {
	username
	not coursejson.fileSystem
	p := [
		k8s_support_init_container,
		k8s_support_containers_volumemount,
		k8s_support_vol,
		termination_grace_period_seconds,
		log_name_envar,
		nb_umask_envar,
		working_dir,
		datasets_volume,
		datasets_volumemount,
		dhsm_volume,
		dhsm_volumemount,
		nbmessages_volume,
		nbmessages_volumemount,
		datasets_2_volume,
		datasets_2_volumemount,
	]
}

patch[p] {
	username
	coursejson.fileSystem
	p := [
		k8s_support_init_container,
		k8s_support_containers_volumemount,
		k8s_support_vol,
		termination_grace_period_seconds,
		log_name_envar,
		nb_umask_envar,
		working_dir,
		datasets_volume,
		datasets_volumemount,
		dhsm_volume,
		dhsm_volumemount,
		nbmessages_volume,
		nbmessages_volumemount,
		datasets_2_volume,
		datasets_2_volumemount,
	]
}

######################### TESTS #########################

test_all_patches_added_when_uid_specified {
	patch[[
		k8s_support_init_container,
		k8s_support_containers_volumemount,
		k8s_support_vol,
		termination_grace_period_seconds,
		log_name_envar,
		nb_umask_envar,
		working_dir,
		datasets_volume,
		datasets_volumemount,
		dhsm_volume,
		dhsm_volumemount,
		nbmessages_volume,
		nbmessages_volumemount,
		datasets_2_volume,
		datasets_2_volumemount,
	]] with input.request as {"object": {
		"metadata": {
			"labels": {"dsmlp/user": "dhub19"},
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
