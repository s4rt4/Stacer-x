import QtQuick
import Stacer

// Full-color brand logo. Rendered as-is (no ColorOverlay), crisp at HiDPI.
Image {
    property int size: 22

    source: Theme.logo
    width: size
    height: size
    sourceSize.width: size * 3
    sourceSize.height: size * 3
    fillMode: Image.PreserveAspectFit
    smooth: true
    mipmap: true
}
