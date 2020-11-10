//
//  YShaders.metal
//  LLMetal
//
//  Created by keith on 2020/11/10.
//

#include <metal_stdlib>
using namespace metal;

//导入桥接文件
#import "YShaderTypes.h"

//定义一个 顶点着色器输出 和 片段着色器输入 的结构体
typedef struct {
    //处理空间的顶点信息
    float4 clipSpacePosition [[position]];

    //颜色
    float4 color;

} RasterizerData;


//顶点着色函数
/*
 vertex  顶点着色函数修饰符
 RasterizerData  函数返回值
 vertexShader 函数名
 传入参数（变量类型   变量名  [[变量在buffer中的索引位置，表示是哪一个]]）
 */
vertex RasterizerData vertexShader (
             uint vertexID [[vertex_id]],
             constant LLVertex *vertices [[buffer(LLVertexInputIndexVertices)]],
             constant vector_uint2 *viewportSizePointer [[buffer(LLVertexInputIndexViewportSize)]])
{

    /*
    处理顶点数据:
       1) 执行坐标系转换,将生成的顶点剪辑空间写入到返回值中.
       2) 将顶点颜色值传递给返回值
    */
    
    //定义out
    RasterizerData out;
    
    out.clipSpacePosition = vertices[vertexID].position;
    
    out.color = vertices[vertexID].color;
    
    return out;
}



//片元着色函数
/*
 fragment 片元着色函数修饰符
 float4 返回值类型
 fragmentShader 函数名
  传入参数（变量类型   变量名  [[变量在buffer中的索引位置，表示是哪一个]]）
 
 [[stage_in]] 专门修饰 由顶点函数输出 经过光栅化生成 传入片元函数的数据
 */
fragment float4 fragmentShader(RasterizerData in [[stage_in]]) {
    
    //返回输入的片元颜色
    return in.color;
}

