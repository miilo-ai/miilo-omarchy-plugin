import QtQuick
import ".." as Miilo

Miilo.SetupListing {
    required property var controller
    agents: controller.agents
}
