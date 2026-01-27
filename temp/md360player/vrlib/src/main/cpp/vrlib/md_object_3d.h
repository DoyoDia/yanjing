#pragma once

#include <vector>
#include <GLES3/gl3.h>

namespace asha {
namespace vrlib {

class MDObject3D {
public:
    // 投影模式枚举（与 ETS 层保持一致）
    enum ProjectionType {
        SPHERE = 201,
        DOME180 = 202,
        DOME230 = 203,
        DOME180_UPPER = 204,
        DOME230_UPPER = 205,
        CUBE = 214,
    };

    MDObject3D();
    virtual ~MDObject3D();

    // 加载不同投影模式的 3D 对象
    void LoadSphere();
    void LoadDome(float degree, bool isUpper);
    void LoadCube();
    
    // 设置投影模式（便捷方法）
    void SetProjectionType(ProjectionType type);
    ProjectionType GetProjectionType() const { return projection_type_; }
    
    // 上传数据到 GPU
    void UploadData();
    
    // 执行绘制
    void Draw();

    // 销毁资源
    void Destroy();

private:
    // 生成不同几何体的算法
    void GenerateSphere(float radius, int rings, int sectors);
    void GenerateDome(float radius, int sectors, float degreeY, bool isUpper);
    void GenerateCube(float size);
    
    // 清空当前数据
    void ClearData();

private:
    ProjectionType projection_type_ = SPHERE;

private:
    std::vector<float> vertices_;
    std::vector<float> texcoords_;
    std::vector<short> indices_;

    GLuint vbo_vertices_ = 0;
    GLuint vbo_texcoords_ = 0;
    GLuint ibo_indices_ = 0;
    
    int num_indices_ = 0;
    bool data_uploaded_ = false;
};

}
}
