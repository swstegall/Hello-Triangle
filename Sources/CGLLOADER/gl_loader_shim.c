#include <glad/glad.h>
#include <GLFW/glfw3.h>

void* gladSwiftLoader(const char* name) {
  return glfwGetProcAddress(name);
}
