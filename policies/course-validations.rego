package kubernetes.admission

contains(arr, elem) {
	arr[_] = elem
}

courseinfo := fetch_user_courses(username)

enrollments[course] {
	course := courseinfo.body[_].course
}

coursejson := fetch_course(course)

default use_umbrellas = false

use_umbrellas {
	coursejson.fileSystem
}

default is_grader = false

is_grader {
	coursejson
	coursejson.grader
	coursejson.grader.username == username
}

deny[msg] {
	not contains(enrollments, course)
	msg := sprintf("%s is not registered for %s!", [username, course])
}
