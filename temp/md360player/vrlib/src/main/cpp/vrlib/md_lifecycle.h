//
// Created on 2025/8/23.
//

#ifndef MD360PLAYER4OH_MD_LIFECYCLE_H
#define MD360PLAYER4OH_MD_LIFECYCLE_H

#include <string>

namespace asha {
namespace vrlib {

class MD360LifecycleAPI {
public:
    virtual int Init() = 0;
    virtual int Destroy() = 0;
    virtual int Pause() = 0;
    virtual int Resume() = 0;
};

}
};


#endif //MD360PLAYER4OH_MD_LIFECYCLE_H

