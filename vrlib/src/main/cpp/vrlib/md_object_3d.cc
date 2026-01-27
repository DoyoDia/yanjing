#include "md_object_3d.h"
#include <cmath>
#include "md_log.h"

namespace asha {
namespace vrlib {

MDObject3D::MDObject3D() : projection_type_(SPHERE) {
}

MDObject3D::~MDObject3D() {
    Destroy();
}

void MDObject3D::LoadSphere() {
    ClearData();
    projection_type_ = SPHERE;
    // 默认参数: radius=18, rings=75, sectors=150 (参考 MDSphere3D.java)
    GenerateSphere(18.0f, 75, 150);
}

void MDObject3D::LoadDome(float degree, bool isUpper) {
    ClearData();
    projection_type_ = isUpper ? (degree == 180.0f ? DOME180_UPPER : DOME230_UPPER) 
                                : (degree == 180.0f ? DOME180 : DOME230);
    // 默认参数: radius=18, sectors=150 (参考 MDDome3D.java)
    GenerateDome(18.0f, 150, degree, isUpper);
}

void MDObject3D::LoadCube() {
    ClearData();
    projection_type_ = CUBE;
    // 立方体大小，使用与球体相同的半径以保持一致性
    GenerateCube(18.0f);
}

void MDObject3D::SetProjectionType(ProjectionType type) {
    projection_type_ = type;
    // 根据类型重新加载几何体
    switch (type) {
        case SPHERE:
            LoadSphere();
            break;
        case DOME180:
            LoadDome(180.0f, false);
            break;
        case DOME230:
            LoadDome(230.0f, false);
            break;
        case DOME180_UPPER:
            LoadDome(180.0f, true);
            break;
        case DOME230_UPPER:
            LoadDome(230.0f, true);
            break;
        case CUBE:
            LoadCube();
            break;
        default:
            LoadSphere();
            break;
    }
}

void MDObject3D::ClearData() {
    vertices_.clear();
    texcoords_.clear();
    indices_.clear();
    num_indices_ = 0;
    data_uploaded_ = false;
    
    // 如果已经上传到 GPU，需要先销毁
    if (vbo_vertices_ != 0 || vbo_texcoords_ != 0 || ibo_indices_ != 0) {
        Destroy();
    }
}

void MDObject3D::GenerateSphere(float radius, int rings, int sectors) {
    const float PI = 3.14159265358979323846f;
    const float PI_2 = PI / 2.0f;

    float R = 1.0f / (float)rings;
    float S = 1.0f / (float)sectors;
    
    int numPoint = (rings + 1) * (sectors + 1);
    
    vertices_.resize(numPoint * 3);
    texcoords_.resize(numPoint * 2);
    indices_.resize(rings * sectors * 6);

    int t = 0, v = 0;
    for(int r = 0; r < rings + 1; r++) {
        for(int s = 0; s < sectors + 1; s++) {
            float x = (float) (cos(2*PI * s * S) * sin( PI * r * R ));
            float y = - (float) sin( -PI_2 + PI * r * R );
            float z = (float) (sin(2*PI * s * S) * sin( PI * r * R ));

            texcoords_[t++] = s*S;
            texcoords_[t++] = 1 - r*R;

            vertices_[v++] = x * radius;
            vertices_[v++] = y * radius;
            vertices_[v++] = z * radius;
        }
    }

    int counter = 0;
    int sectorsPlusOne = sectors + 1;
    for(int r = 0; r < rings; r++){
        for(int s = 0; s < sectors; s++) {
            indices_[counter++] = (short) (r * sectorsPlusOne + s);       //(a)
            indices_[counter++] = (short) ((r+1) * sectorsPlusOne + (s));    //(b)
            indices_[counter++] = (short) ((r) * sectorsPlusOne + (s+1));  // (c)
            indices_[counter++] = (short) ((r) * sectorsPlusOne + (s+1));  // (c)
            indices_[counter++] = (short) ((r+1) * sectorsPlusOne + (s));    //(b)
            indices_[counter++] = (short) ((r+1) * sectorsPlusOne + (s+1));  // (d)
        }
    }
    
    num_indices_ = indices_.size();
}

void MDObject3D::GenerateDome(float radius, int sectors, float degreeY, bool isUpper) {
    const float PI = 3.14159265358979323846f;
    const float PI_2 = PI / 2.0f;
    
    float percent = degreeY / 360.0f;
    int rings = sectors >> 1;  // sectors / 2
    
    float R = 1.0f / (float)rings;
    float S = 1.0f / (float)sectors;
    
    int lenRings = (int)(rings * percent) + 1;
    int lenSectors = sectors + 1;
    int numPoint = lenRings * lenSectors;
    
    vertices_.resize(numPoint * 3);
    texcoords_.resize(numPoint * 2);
    indices_.resize((lenRings - 1) * (lenSectors - 1) * 6);
    
    int upper = isUpper ? 1 : -1;
    
    int t = 0, v = 0;
    for (int r = 0; r < lenRings; r++) {
        for (int s = 0; s < lenSectors; s++) {
            float x = (float)(cos(2 * PI * s * S) * sin(PI * r * R)) * upper;
            float y = (float)sin(-PI_2 + PI * r * R) * -upper;
            float z = (float)(sin(2 * PI * s * S) * sin(PI * r * R));
            
            // 纹理坐标计算（参考 Android 实现）
            float a = (float)(cos(2 * PI * s * S) * r * R / percent) / 2.0f + 0.5f;
            float b = (float)(sin(2 * PI * s * S) * r * R / percent) / 2.0f + 0.5f;
            
            texcoords_[t++] = b;
            texcoords_[t++] = a;
            
            vertices_[v++] = x * radius;
            vertices_[v++] = y * radius;
            vertices_[v++] = z * radius;
        }
    }
    
    int counter = 0;
    for (int r = 0; r < lenRings - 1; r++) {
        for (int s = 0; s < lenSectors - 1; s++) {
            indices_[counter++] = (short)(r * lenSectors + s);
            indices_[counter++] = (short)((r + 1) * lenSectors + s);
            indices_[counter++] = (short)(r * lenSectors + (s + 1));
            indices_[counter++] = (short)(r * lenSectors + (s + 1));
            indices_[counter++] = (short)((r + 1) * lenSectors + s);
            indices_[counter++] = (short)((r + 1) * lenSectors + (s + 1));
        }
    }
    
    num_indices_ = counter;
}

void MDObject3D::GenerateCube(float size) {
    // 立方体有 6 个面，每个面有 2 个三角形，共 12 个三角形，36 个顶点（每个顶点重复 3 次）
    // 为了简化，我们使用索引缓冲区，每个面 4 个顶点，共 24 个顶点
    const int numVertices = 24;  // 6 个面 * 4 个顶点
    const int numIndices = 36;   // 6 个面 * 2 个三角形 * 3 个顶点
    
    vertices_.resize(numVertices * 3);
    texcoords_.resize(numVertices * 2);
    indices_.resize(numIndices);
    
    float halfSize = size / 2.0f;
    
    // 定义立方体的 8 个顶点
    float vertices[8][3] = {
        {-halfSize, -halfSize, -halfSize},  // 0: 左下后
        { halfSize, -halfSize, -halfSize},  // 1: 右下后
        { halfSize,  halfSize, -halfSize},  // 2: 右上后
        {-halfSize,  halfSize, -halfSize},  // 3: 左上后
        {-halfSize, -halfSize,  halfSize},  // 4: 左下前
        { halfSize, -halfSize,  halfSize},  // 5: 右下前
        { halfSize,  halfSize,  halfSize},  // 6: 右上前
        {-halfSize,  halfSize,  halfSize}   // 7: 左上前
    };
    
    // 定义 6 个面的顶点索引（每个面 4 个顶点）
    int faces[6][4] = {
        {0, 1, 2, 3},  // 后面 (Z-)
        {5, 4, 7, 6},  // 前面 (Z+)
        {4, 0, 3, 7},  // 左面 (X-)
        {1, 5, 6, 2},  // 右面 (X+)
        {4, 5, 1, 0},  // 下面 (Y-)
        {3, 2, 6, 7}   // 上面 (Y+)
    };
    
    // 定义每个面的纹理坐标
    float texCoords[4][2] = {
        {0.0f, 0.0f},  // 左下
        {1.0f, 0.0f},  // 右下
        {1.0f, 1.0f},  // 右上
        {0.0f, 1.0f}   // 左上
    };
    
    // 填充顶点和纹理坐标
    int v = 0, t = 0;
    for (int face = 0; face < 6; face++) {
        for (int vertex = 0; vertex < 4; vertex++) {
            int vertexIndex = faces[face][vertex];
            vertices_[v++] = vertices[vertexIndex][0];
            vertices_[v++] = vertices[vertexIndex][1];
            vertices_[v++] = vertices[vertexIndex][2];
            
            texcoords_[t++] = texCoords[vertex][0];
            texcoords_[t++] = texCoords[vertex][1];
        }
    }
    
    // 填充索引（每个面 2 个三角形）
    int counter = 0;
    for (int face = 0; face < 6; face++) {
        int base = face * 4;
        // 第一个三角形
        indices_[counter++] = (short)(base + 0);
        indices_[counter++] = (short)(base + 1);
        indices_[counter++] = (short)(base + 2);
        // 第二个三角形
        indices_[counter++] = (short)(base + 0);
        indices_[counter++] = (short)(base + 2);
        indices_[counter++] = (short)(base + 3);
    }
    
    num_indices_ = counter;
}

void MDObject3D::UploadData() {
    if (vertices_.empty()) return;

    if (vbo_vertices_ == 0) {
        glGenBuffers(1, &vbo_vertices_);
        glGenBuffers(1, &vbo_texcoords_);
        glGenBuffers(1, &ibo_indices_);
    }

    glBindBuffer(GL_ARRAY_BUFFER, vbo_vertices_);
    glBufferData(GL_ARRAY_BUFFER, vertices_.size() * sizeof(float), vertices_.data(), GL_STATIC_DRAW);

    glBindBuffer(GL_ARRAY_BUFFER, vbo_texcoords_);
    glBufferData(GL_ARRAY_BUFFER, texcoords_.size() * sizeof(float), texcoords_.data(), GL_STATIC_DRAW);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo_indices_);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices_.size() * sizeof(short), indices_.data(), GL_STATIC_DRAW);
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    
    data_uploaded_ = true;
}

void MDObject3D::Draw() {
    if (!data_uploaded_) {
        UploadData();
    }
    
    if (vbo_vertices_ == 0) return;

    // 绑定 VBO
    glBindBuffer(GL_ARRAY_BUFFER, vbo_vertices_);
    // 假设 layout 0 是 position
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);

    glBindBuffer(GL_ARRAY_BUFFER, vbo_texcoords_);
    // 假设 layout 1 是 texCoord
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 0, 0);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo_indices_);
    glDrawElements(GL_TRIANGLES, num_indices_, GL_UNSIGNED_SHORT, 0);

    glDisableVertexAttribArray(0);
    glDisableVertexAttribArray(1);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}

void MDObject3D::Destroy() {
    if (vbo_vertices_ != 0) {
        glDeleteBuffers(1, &vbo_vertices_);
        vbo_vertices_ = 0;
    }
    if (vbo_texcoords_ != 0) {
        glDeleteBuffers(1, &vbo_texcoords_);
        vbo_texcoords_ = 0;
    }
    if (ibo_indices_ != 0) {
        glDeleteBuffers(1, &ibo_indices_);
        ibo_indices_ = 0;
    }
    data_uploaded_ = false;
}

}
}
