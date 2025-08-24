@preconcurrency import CGLAD
import CGLFW
import CGLLOADER

let framebufferSizeCallback: GLFWframebuffersizefun = { _, width, height in
  print("Resizing window to \(width)x\(height).")
  glViewport(0, 0, width, height)
}

func processInput(window: OpaquePointer!) {
  if glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS {
    print("Closing window since user hit ESC.")
    glfwSetWindowShouldClose(window, GLFW_TRUE)
  }
}

let vertices: [Float] = [
  -0.5, -0.5, 0.0,
   0.5, -0.5, 0.0,
   0.0,  0.5, 0.0
]

let vertexShaderSource = """
#version 410 core
layout (location = 0) in vec3 aPos;

void main()
{
  gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
}
"""

let fragmentShaderSource = """
#version 410 core
out vec4 FragColor;

void main()
{
  FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
}
"""

@main
class HelloTriangle {
  static func main() {
    setupOpenGLContext()
    guard let window = glfwCreateWindow(800, 600, "Hello Triangle", nil, nil) else {
      glfwTerminate()
      fatalError("Failed to create GLFW window.")
    }
    
    setupWindow(window: window)
    
    renderLoop(window: window)
    glfwTerminate()
  }
  
  static func setupOpenGLContext() {
    glfwInit()
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4)
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1)
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE)
    #if(os(macOS))
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE)
    #endif
  }
  
  static func setupWindow(window: OpaquePointer!) {
    glfwMakeContextCurrent(window)
    if gladLoadGLLoader(gladSwiftLoader) == 0 {
      fatalError("Failed to initialize GLAD")
    }
    glViewport(0, 0, 800, 600)
    glfwSetFramebufferSizeCallback(window, framebufferSizeCallback)
  }
  
  static func renderLoop(window: OpaquePointer!) {
    // MARK: Vertex Shader.
    let vertexShader: GLuint = glCreateShader(GLenum(GL_VERTEX_SHADER))
    vertexShaderSource.withCString { ptr in
      var cStringPtr: UnsafePointer<GLchar>? = UnsafePointer(ptr)
      glShaderSource(vertexShader, 1, &cStringPtr, nil)
    }
    glCompileShader(vertexShader)
    var status: GLint = 0
    glGetShaderiv(vertexShader, GLenum(GL_COMPILE_STATUS), &status)
    if status == GL_FALSE {
      var logLength: GLint = 0
      glGetShaderiv(vertexShader, GLenum(GL_INFO_LOG_LENGTH), &logLength)
      var log = [GLchar](repeating: 0, count: Int(logLength))
      glGetShaderInfoLog(vertexShader, logLength, nil, &log)
      print("Vertex shader compile error: \(String(cString: log))")
    }
    
    // MARK: Fragment Shader.
    let fragmentShader: GLuint = glCreateShader(GLenum(GL_FRAGMENT_SHADER))
    fragmentShaderSource.withCString { ptr in
      var cStringPtr: UnsafePointer<GLchar>? = UnsafePointer(ptr)
      glShaderSource(fragmentShader, 1, &cStringPtr, nil)
    }
    glCompileShader(fragmentShader)
    status = 0
    glGetShaderiv(fragmentShader, GLenum(GL_COMPILE_STATUS), &status)
    if status == GL_FALSE {
      var logLength: GLint = 0
      glGetShaderiv(fragmentShader, GLenum(GL_INFO_LOG_LENGTH), &logLength)
      var log = [GLchar](repeating: 0, count: Int(logLength))
      glGetShaderInfoLog(fragmentShader, logLength, nil, &log)
      print("Fragment shader compile error: \(String(cString: log))")
    }
    
    // MARK: Shader Program.
    let shaderProgram: GLuint = glCreateProgram()
    glAttachShader(shaderProgram, vertexShader)
    glAttachShader(shaderProgram, fragmentShader)
    glLinkProgram(shaderProgram)
    status = 0
    glGetProgramiv(shaderProgram, GLenum(GL_LINK_STATUS), &status)
    if status == GL_FALSE {
      var log = [GLchar](repeating: 0, count: Int(512))
      glGetProgramInfoLog(shaderProgram, 512, nil, &log)
      print("Shader program linking error: \(String(cString: log))")
    }
    
    glDeleteShader(vertexShader)
    glDeleteShader(fragmentShader)

    var VBO: GLuint = 0
    var VAO: GLuint = 0
    glad_glGenVertexArrays(1, &VAO)
    glGenBuffers(1, &VBO)
    // Bind the Vertex Array Object first, the bind and set vertex buffer(s), and then configure vertex attribute(s).
    glad_glBindVertexArray(VAO)
    print("VBO: \(VBO), VAO: \(VAO)")
    glBindBuffer(GLenum(GL_ARRAY_BUFFER), VBO)
    glBufferData(
      GLenum(GL_ARRAY_BUFFER),
      vertices.count * MemoryLayout<Float>.stride,
      vertices,
      GLenum(GL_STATIC_DRAW)
    )
    glVertexAttribPointer(
      0,
      3,
      GLenum(GL_FLOAT),
      GLboolean(GLenum(GL_FALSE)),
      GLsizei(3 * MemoryLayout<Float>.stride),
      nil
    )
    glEnableVertexAttribArray(0)
    
    // Note that this is allowed, the call to glVertexAttribPointer regestered VBO as the vertex attribute's bound vertex buffer object so afterwards we can safely unbind.
    glBindBuffer(GLenum(GL_ARRAY_BUFFER), 0)
    
    // You can unbind the VAO afterwards so other VAO calls won't accidentally modify this VAO, but this rarely happens. Modifying other VAOs requires a call to glBindVertexArray anyway so we generally don't unbind VAOs (nor VBOs) when it's not directly necessary.
    
    while(glfwWindowShouldClose(window) == GLFW_FALSE) {
      // Input.
      processInput(window: window)
      
      // Rendering commands here.
      // MARK: Background Clear.
      glClearColor(0.2, 0.3, 0.3, 1.0)
      glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
      
      // MARK: Use Shader Program.
      glUseProgram(shaderProgram)
      glBindVertexArrayAPPLE(VAO)
      glDrawArrays(GLenum(GL_TRIANGLES), 0, 3)
      
      // Check and call events and swap the buffers.
      glfwSwapBuffers(window)
      glfwPollEvents()
    }
  }
}
