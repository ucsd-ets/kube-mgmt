package kubernetes.admission

# Mounts /home/username and /home/username/private

get_user_homepath(username) = homepath {
	homepath := concat("/", ["/home", username])
}

get_grader_homepath(course) = homepath {
	homepath := sprintf("/srv/nbgrader/%s", [course])
}

# non-umbrella graders use /srv/nbgrader/$course
get_homepath(i) = homepath {
	is_grader
	not use_umbrellas
	homepath := get_grader_homepath(course)
}

# non-graders use /home/user
get_homepath(i) = homepath {
	not is_grader
	not use_umbrellas
	homepath := get_user_homepath(i)
}

# umbrella user's always use /home/user
get_homepath(i) = homepath {
	use_umbrellas
	homepath := get_user_homepath(i)
}

umbrella_volume(username, course, server, path) = patch {
	patch := {
		"op": "add",
		"path": "/spec/volumes/-",
		"value": {
			"name": "course-umbrella",
			"nfs": {
				"server": server,
				"path": sprintf("%s/%s", [path, course]),
			},
		},
	}
}

umbrella_volume_mount(username) = patch {
	patch := {
		"op": "add",
		"path": "/spec/containers/0/volumeMounts/-",
		"value": {
			"name": "course-umbrella",
			"mountPath": get_user_homepath(username),
			"subPath": sprintf("home/%s", [username]),
		},
	}
}

home_volume := {
	"op": "add",
	"path": "/spec/volumes/-",
	"value": {
		"name": "home",
		"persistentVolumeClaim": {"claimName": "home"},
	},
}

home_volume_mount(username) = patch {
	patch := {
		"op": "add",
		"path": "/spec/containers/0/volumeMounts/-",
		"value": {
			"name": "home",
			"mountPath": get_user_homepath(username),
		},
	}
}

private_home_volume_mount(username) = patch {
	patch := {
		"op": "add",
		"path": "/spec/containers/0/volumeMounts/-",
		"value": {
			"name": "home",
			"mountPath": sprintf("/home/%s/private", [username]),
		},
	}
}

home_env_var(path) = patch {
	patch := {
		"op": "add",
		"path": "/spec/containers/0/env/-",
		"value": {
			"name": "HOME",
			"value": path,
		},
	}
}

patch[p] {
	# if we're using umbrellas, add user's course umbrella home volume
	use_umbrellas
	p := [umbrella_volume(username, course, coursejson.fileSystem.server, coursejson.fileSystem.path)]
}

patch[p] {
	# if we're using umbrellas, mount the user's course umbrella home to /home/username
	use_umbrellas
	p := [umbrella_volume_mount(username)]
}

patch[p] {
	# if auto config is on, add a home volume
	auto_config
	p := [home_volume]
}

patch[p] {
	# if we're not using umbrellas, don't mount user's home directory to /home/username
	not use_umbrellas
	p := [home_volume_mount(username)]
}

patch[p] {
	# if we're using umbrellas, mount the user's home directory to /home/username/private
	use_umbrellas
	p := [private_home_volume_mount(username)]
}

patch[p] {
	# if we're using umbrellas, mount the user's home directory to /home/username/private
	# use_umbrellas
	p := [home_env_var(get_homepath(username))]
}
