# Mounts /srv/nbgrader/COURSE/exchange and sets NBGRADER_COURSEID
package kubernetes.admission

nbgrader_umbrella_exchange_volume_mount_patch(course) = patch {
	patch := {
		"op": "add",
		"path": "/spec/containers/0/volumeMounts/-",
		"value": {
			"name": "course-umbrella",
			"mountPath": sprintf("/srv/nbgrader/%s/exchange", [course]),
			"subPath": "nbgrader/exchange",
		},
	}
}

nbgrader_umbrella_config_volume_mount_patch := {
	"op": "add",
	"path": "/spec/containers/0/volumeMounts/-",
	"value": {
		"name": "course-umbrella",
		"mountPath": "/etc/jupyter/nbgrader_config.py",
		"subPath": "nbgrader/config/nbgrader_config.py",
	},
}

nbgrader_grader_volume_mount_patch(course) = patch {
	patch := {
		"op": "add",
		"path": "/spec/containers/0/volumeMounts/-",
		"value": {
			"name": "nbgrader",
			"mountPath": concat("/", ["/srv/nbgrader", course]),
			"subPath": concat("/", [course, "grader"]),
		},
	}
}

nbgrader_volume_patch := {
	"op": "add",
	"path": "/spec/volumes/-",
	"value": {
		"name": "nbgrader",
		"persistentVolumeClaim": {"claimName": "nbgrader"},
	},
}

nbgrader_volume_mount_patch2(course) = patch {
	patch := {
		"op": "add",
		"path": "/spec/containers/0/volumeMounts/-",
		"value": {
			"name": "nbgrader",
			"mountPath": "/srv/nbgrader/exchange",
			"subPath": concat("/", [course, "exchange"]),
		},
	}
}

nbgrader_env_patch2(course) = patch {
	patch := {
		"op": "add",
		"path": "/spec/containers/0/env/-",
		"value": {
			"name": "NBGRADER_COURSEID",
			"value": course,
		},
	}
}

nbgrader_config_volume_mount_patch2(course) = patch {
	patch := {
		"op": "add",
		"path": "/spec/containers/0/volumeMounts/-",
		"value": {
			"name": "nbgrader",
			"mountPath": "/etc/jupyter/nbgrader_config.py",
			"subPath": concat("/", [course, "config/nbgrader_config.py"]),
		},
	}
}

nbgrader_grader_volume_mount2(course) = patch {
	patch := {
		"op": "add",
		"path": "/spec/containers/0/volumeMount/-",
		"value": {
			"name": "nbgrader",
			"mountPath": "/srv/nbgrader",
			"subPath": concat("/", [course, "grader"]),
		},
	}
}

patch[p] {
	use_umbrellas
	p := [nbgrader_umbrella_exchange_volume_mount_patch(course)]
}

patch[p] {
	use_umbrellas
	p := [nbgrader_umbrella_config_volume_mount_patch]
}

patch[p] {
	# if we're using umbrellas, add user's course umbrella home volume
	# use_umbrellas
	auto_config
	not use_umbrellas
	p := [nbgrader_volume_patch]
}

patch[p] {
	# if we're using umbrellas, add user's course umbrella home volume
	# use_umbrellas
	auto_config
	not use_umbrellas
	p := [nbgrader_volume_mount_patch2(course)]
}

patch[p] {
	# if we're using umbrellas, add user's course umbrella home volume
	# use_umbrellas
	auto_config
	p := [nbgrader_env_patch2(course)]
}

patch[p] {
	# if we're using umbrellas, add user's course umbrella home volume
	# use_umbrellas
	auto_config
	not use_umbrellas
	p := [nbgrader_config_volume_mount_patch2(course)]
}

patch[p] {
	# if we're using umbrellas, add user's course umbrella home volume
	# use_umbrellas
	auto_config
	not use_umbrellas
	p := [nbgrader_grader_volume_mount2(course)]
}

patch[p] {
	# if we're using umbrellas, add user's course umbrella home volume
	# use_umbrellas
	auto_config
	not use_umbrellas
	is_grader
	p := [nbgrader_grader_volume_mount_patch(course)]
}
