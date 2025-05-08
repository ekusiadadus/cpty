.phony:

build:
	@echo "Building the project..."
	@echo "This is a placeholder for the build process."
	@echo "You can add your build commands here."
	zig build
	@echo "Build completed."

clean:
	@echo "Cleaning up the project..."
	@echo "This is a placeholder for the clean process."
	@echo "You can add your clean commands here."
	zig build -Drelease-fast
	@echo "Clean completed."

run:
	@echo "Running the project..."
	@echo "This is a placeholder for the run process."
	@echo "You can add your run commands here."
	zig build run
	@echo "Run completed.

exe:
	zig build-exe src/main.zig


