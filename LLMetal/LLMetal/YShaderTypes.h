//
//  YShaderTypes.h
//  LLMetal
//
//  Created by keith on 2020/11/10.
//

#ifndef YShaderTypes_h
#define YShaderTypes_h

//目的：为了桥接 metal shader和oc代码之间共用的部分。
//因为这里的代码 多个文件都要用到
//所以单独一个类出来，让shader和oc代码都能调用

//需要定义枚举值来传递数据
typedef enum LLVertexInputIndex {
    //顶点
    LLVertexInputIndexVertices     = 0,
    //视图大小
    LLVertexInputIndexViewportSize = 1,
    
} LLVertexInputIndex;


//结构体: 顶点/颜色值
typedef struct {
    // 像素空间的位置
    // 像素中心点(100,100)
    vector_float4 position;

    // RGBA颜色
    vector_float4 color;
    
} LLVertex;

#endif /* YShaderTypes_h */
