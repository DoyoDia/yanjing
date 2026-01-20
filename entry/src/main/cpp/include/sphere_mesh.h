/**
 * sphere_mesh.h - 球体网格生成器
 * 用于生成 UV 球体顶点和索引数据
 */

#ifndef SPHERE_MESH_H
#define SPHERE_MESH_H

#include <vector>

namespace PanoramaVR {

/**
 * 球体顶点数据结构
 */
struct SphereVertex {
    float x, y, z;      // 位置
    float u, v;         // 纹理坐标
};

/**
 * 球体网格类
 * 生成用于全景渲染的倒置球体（内部可见）
 */
class SphereMesh {
public:
    /**
     * 生成球体网格
     * @param latitudeBands 纬度分段数（越大越平滑）
     * @param longitudeBands 经度分段数（越大越平滑）
     * @param radius 球体半径
     * @param invertNormals 是否反转法线（用于内部渲染）
     */
    static void Generate(
        int latitudeBands,
        int longitudeBands,
        float radius,
        bool invertNormals,
        std::vector<SphereVertex>& outVertices,
        std::vector<unsigned short>& outIndices
    );
};

} // namespace PanoramaVR

#endif // SPHERE_MESH_H
