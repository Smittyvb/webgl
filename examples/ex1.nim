import dom, ../src/webgl

var vertexPositionAttribute : uint 

proc getShader(gl:WebGLRenderingContext, id:string, kind:char):WebGLShader =
    var shaderScript = dom.document.getElementById(id)
    if (shaderScript==nil): return
    var theSource : string = ""
    var currentChild = shaderScript.firstChild
    while(currentChild!=nil):
        if (currentChild.nodeType == dom.TextNode):
            theSource &= currentChild.nodeValue
        currentChild = currentChild.nextSibling
    
    if(kind == 'f'): result = gl.createShader(seFRAGMENT_SHADER)
    elif(kind == 'v'): result = gl.createShader(seVERTEX_SHADER)
    else: return #unknown shader type

    gl.shaderSource(result, theSource)

    # Compile shader
    gl.compileShader(result)

    # See if it compiled successfully
    {. emit: "if (!`gl`.getShaderParameter(`result`, `gl`.COMPILE_STATUS)) {alert('An error occurred compiling the shaders: ' + `gl`.getShaderInfoLog(`result`));return null;}; ".}  

var shaderProgram : WebGLProgram
proc initShaders(gl:WebGLRenderingContext) =
    var fragmentShader = getShader(gl, "shader-fs",'f')
    var vertexShader = getShader(gl, "shader-vs",'v');

    #Create shader programs
    shaderProgram = gl.createProgram()
    gl.attachShader(shaderProgram,vertexShader)
    gl.attachShader(shaderProgram,fragmentShader)
    gl.linkProgram(shaderProgram)

    # If creating the shader program failed, alert
    # I'm lazy so I'll just emit this directly
    #  {.emit : "if (!`gl`.getProgramParameter(`shaderProgram`, `gl`.LINK_STATUS)) { alert('Unable to initialize the shader program: ' + `gl`.getProgramInfoLog(`shader`)); };" .}

    gl.useProgram(shaderProgram)

    
    vertexPositionAttribute = gl.getAttribLocation(shaderProgram, "aVertexPosition");
    gl.enableVertexAttribArray(vertexPositionAttribute);

var squareVerticesBuffer : WebGLBuffer

proc initBuffers(gl:WebGLRenderingContext) =
    squareVerticesBuffer = gl.createBuffer()

    gl.bindBuffer(beARRAY_BUFFER, squareVerticesBuffer)

    var vertices :seq[float32]= @[
        1.0'f32,  1.0,  0.0,
        -1.0, 1.0,  0.0,
        1.0,  -1.0, 0.0,
        -1.0, -1.0, 0.0
    ];
    
    gl.bufferData(beARRAY_BUFFER, vertices, beSTATIC_DRAW);


proc setMatrixUniforms(gl:WebGLRenderingContext,pm, mv: seq[float]) =
    var pUniform = gl.getUniformLocation(shaderProgram,"uPMatrix")
    gl.uniformMatrix4fv(pUniform,false, pm)

    var mvUniform = gl.getUniformLocation(shaderProgram,"uMVMatrix")
    gl.uniformMatrix4fv(mvUniform,false, mv)

proc drawScene(gl:WebGLRenderingContext) =
    gl.clear(bbCOLOR.uint or bbDEPTH.uint);
    
    var perspectiveMatrix = newSeq[float](16)
    perspective4(45, 640.0/480.0, 0.1, 100.0, perspectiveMatrix);
    

    var mv = newSeq[float](16)
    mv.identity4();
    mv.traslate4([-0.0, 0.0, -6.0],mv);
    
    gl.bindBuffer(beARRAY_BUFFER, squareVerticesBuffer);
    gl.vertexAttribPointer(vertexPositionAttribute, 3, dtFLOAT, false, 0, 0);
    setMatrixUniforms(gl,perspectiveMatrix,mv);
    gl.drawArrays(pmTRIANGLE_STRIP, 0, 4);


dom.window.onload = proc (e: dom.Event) =
    echo sizeof(int)
    echo sizeof(uint)
    echo sizeof(float)
    var canvas = dom.document.getElementById("glcanvas").Canvas;
    var gl = canvas.getContext("webgl")
    if gl.isNil: gl = canvas.getContext("experimental-webgl")

    gl.clearColor(0.0, 0.0, 0.0, 1.0);  # Clear to black, fully opaque 
    gl.clearDepth(1.0);                 # Clear everything 
    
    # Initialize the shaders; this is where all the lighting for the 
    # vertices and so forth is established.  

    initShaders(gl); 

    # Here's where we call the routine that builds all the objects 
    # we'll be drawing. 
    initBuffers(gl); 

    # Set up to draw the scene periodically. 
    #setInterval(drawScene, 15); 
    drawScene(gl)
