.PHONY: clean lint docker_image run_docker_image

#################################################################################
# GLOBALS                                                                       #
#################################################################################

PROJECT_NAME = granary
CONTAINER_NAME = meroe

#################################################################################
# COMMANDS                                                                      #
################################################################

## Delete all compiled Python files
clean:
	find . -type f -name "*.py[co]" -delete
	find . -type d -name "__pycache__" -delete

## Lint using flake8
lint:
	flake8 src

## Test python environment is setup correctly
test_environment: .docker_image_record/$(PROJECT_NAME)
	docker run \
		--name $(CONTAINER_NAME) \
		-v ${CURDIR}:/$(PROJECT_NAME) \
		--rm -it $(PROJECT_NAME) \
		python test_environment.py

## Build and Deploy Docker Image

.docker_image_record:
	@mkdir .docker_image_record

docker_image .docker_image_record/$(PROJECT_NAME): Dockerfile .docker_image_record
	@echo 'Building Docker Image for $(PROJECT_NAME)'
	@DOCKER_BUILDKIT=1
	@docker build \
		-t $(PROJECT_NAME) \
		.
	@touch .docker_image_record/$(PROJECT_NAME)
	@echo 'Built Docker Image for $(PROJECT_NAME)'

run_docker_image: .docker_image_record/$(PROJECT_NAME)
	docker run \
		--name $(CONTAINER_NAME) \
		-v ${CURDIR}:/$(PROJECT_NAME) \
		--rm -it $(PROJECT_NAME)

python_shell: .docker_image_record/$(PROJECT_NAME)
	docker run \
		--name $(CONTAINER_NAME) \
		-v ${CURDIR}:/$(PROJECT_NAME)t \
		--rm -it $(PROJECT_NAME) \
		python

setup_python: setup.py
	docker run \
		--name $(CONTAINER_NAME) \
		-v ${CURDIR}:/$(PROJECT_NAME) \
		--rm -it $(PROJECT_NAME) \
		pip install -e .


bash: .docker_image_record/$(PROJECT_NAME)
	docker run \
		--name $(CONTAINER_NAME) \
		-v ${CURDIR}:/$(PROJECT_NAME) \
		--rm -it $(PROJECT_NAME) \
		bash


#################################################################################
# PROJECT RULES                                                                 #
#################################################################################



#################################################################################
# Self Documenting Commands                                                     #
#################################################################################

.DEFAULT_GOAL := help

# Inspired by <http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html>
# sed script explained:
# /^##/:
# 	* save line in hold space
# 	* purge line
# 	* Loop:
# 		* append newline + line to hold space
# 		* go to next line
# 		* if line starts with doc comment, strip comment character off and loop
# 	* remove target prerequisites
# 	* append hold space (+ newline) to line
# 	* replace newline plus comments by `---`
# 	* print line
# Separate expressions are necessary because labels cannot be delimited by
# semicolon; see <http://stackoverflow.com/a/11799865/1968>
.PHONY: help
help:
	@echo "$$(tput bold)Available rules:$$(tput sgr0)"
	@echo
	@sed -n -e "/^## / { \
		h; \
		s/.*//; \
		:doc" \
		-e "H; \
		n; \
		s/^## //; \
		t doc" \
		-e "s/:.*//; \
		G; \
		s/\\n## /---/; \
		s/\\n/ /g; \
		p; \
	}" ${MAKEFILE_LIST} \
	| LC_ALL='C' sort --ignore-case \
	| awk -F '---' \
		-v ncol=$$(tput cols) \
		-v indent=19 \
		-v col_on="$$(tput setaf 6)" \
		-v col_off="$$(tput sgr0)" \
	'{ \
		printf "%s%*s%s ", col_on, -indent, $$1, col_off; \
		n = split($$2, words, " "); \
		line_length = ncol - indent; \
		for (i = 1; i <= n; i++) { \
			line_length -= length(words[i]) + 1; \
			if (line_length <= 0) { \
				line_length = ncol - indent - length(words[i]) - 1; \
				printf "\n%*s ", -indent, " "; \
			} \
			printf "%s ", words[i]; \
		} \
		printf "\n"; \
	}' \
	| more $(shell test $(shell uname) = Darwin && echo '--no-init --raw-control-chars')
