/**
 * sphere_mesh.cpp - 球体网格生成器实现
 */

#include "include/sphere_mesh.h"
#include <cmath>

namespace PanoramaVR {

void SphereMesh::Generate(
    int latitudeBands,
    int longitudeBands,
    float radius,
    bool invertNormals,
    std::vector<SphereVertex>& outVertices,
    std::vector<unsigned short>& outIndices)
{
    outVertices.clear();
    outIndices.clear();

    // 生成顶点
    for (int lat = 0; lat <= latitudeBands; lat++) {
        float theta = static_cast<float>(lat) * M_PI / static_cast<float>(latitudeBands);
        float sinTheta = std::sin(theta);
        float cosTheta = std::cos(theta);

        for (int lon = 0; lon <= longitudeBands; lon++) {
            float phi = static_cast<float>(lon) * 2.0f * M_PI / static_cast<float>(longitudeBands);
            float sinPhi = std::sin(phi);
            float cosPhi = std::cos(phi);

            SphereVertex vertex;

            // 位置（如果反转，需要反转 X 以保持正确的纹理映射）
            if (invertNormals) {
                // 反转球体：从内部观看
                vertex.x = radius * cosPhi * sinTheta;
                vertex.y = radius * cosTheta;
                vertex.z = radius * sinPhi * sinTheta;
            } else {
                vertex.x = radius * cosPhi * sinTheta;
                vertex.y = radius * cosTheta;
                vertex.z = radius * sinPhi * sinTheta;
            }

            // 纹理坐标
            // 对于等距柱状投影：
            // U: 经度映射到 [0, 1]
            // V: 纬度映射到 [0, 1]
            vertex.u = static_cast<float>(lon) / static_cast<float>(longitudeBands);
            vertex.v = static_cast<float>(lat) / static_cast<float>(latitudeBands);

            // 如果从内部观看，需要翻转 U 坐标以正确显示
            if (invertNormals) {
                vertex.u = 1.0f - vertex.u;
            }

            outVertices.push_back(vertex);
        }
    }

    // 生成索引
    for (int lat = 0; lat < latitudeBands; lat++) {
        for (int lon = 0; lon < longitudeBands; lon++) {
            int first = (lat * (longitudeBands + 1)) + lon;
            int second = first + longitudeBands + 1;

            if (invertNormals) {
                // 反转三角形绕序（从内部观看）
                outIndices.push_back(static_cast<unsigned short>(first));
                outIndices.push_back(static_cast<unsigned short>(first + 1));
                outIndices.push_back(static_cast<unsigned short>(second));

                outIndices.push_back(static_cast<unsigned short>(second));
                outIndices.push_back(static_cast<unsigned short>(first + 1));
                outIndices.push_back(static_cast<unsigned short>(second + 1));
            } else {
                // 正常三角形绕序（从外部观看）
                outIndices.push_back(static_cast<unsigned short>(first));
                outIndices.push_back(static_cast<unsigned short>(second));
                outIndices.push_back(static_cast<unsigned short>(first + 1));

                outIndices.push_back(static_cast<unsigned short>(second));
                outIndices.push_back(static_cast<unsigned short>(second + 1));
                outIndices.push_back(static_cast<unsigned short>(first + 1));
            }
        }
    }
}

} // namespace PanoramaVR
