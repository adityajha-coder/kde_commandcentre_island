cmake_minimum_required(VERSION 3.20)

project(kde-island
    VERSION 0.1.0
    DESCRIPTION "Dynamic Island command center for KDE Plasma on Wayland using Quickshell"
    HOMEPAGE_URL "https://github.com/adityajha-coder/kde_commandcentre_island"
    LANGUAGES NONE
)

include(GNUInstallDirs)

# Options
option(INSTALL_AUTOSTART "Install desktop autostart entry" OFF)

# Default installation directory for Quickshell configurations
set(KDE_ISLAND_INSTALL_DIR "${CMAKE_INSTALL_DATADIR}/quickshell/kde-island" CACHE PATH "Destination directory for kde-island files")

message(STATUS "Configuring ${PROJECT_NAME} v${PROJECT_VERSION}")
message(STATUS "Installation directory: ${KDE_ISLAND_INSTALL_DIR}")

# 1. Install root QML and configuration files
install(
    FILES
        shell.qml
        Island.qml
        ConfigStore.qml
        config.default.json
    DESTINATION "${KDE_ISLAND_INSTALL_DIR}"
)

# 2. Install component and service directories
install(
    DIRECTORY
        assets
        components
        services
    DESTINATION "${KDE_ISLAND_INSTALL_DIR}"
    PATTERN "*.desktop" EXCLUDE
)

# 3. Install scripts with executable permissions
install(
    DIRECTORY
        scripts/
    DESTINATION "${KDE_ISLAND_INSTALL_DIR}/scripts"
    FILE_PERMISSIONS
        OWNER_READ OWNER_WRITE OWNER_EXECUTE
        GROUP_READ GROUP_EXECUTE
        WORLD_READ WORLD_EXECUTE
)

# 4. Optional autostart entry
if(INSTALL_AUTOSTART)
    install(
        FILES assets/kde-island.desktop
        DESTINATION "${CMAKE_INSTALL_SYSCONFDIR}/xdg/autostart"
    )
    message(STATUS "Autostart entry enabled: ${CMAKE_INSTALL_SYSCONFDIR}/xdg/autostart/kde-island.desktop")
endif()

# 5. Optional QML lint target
find_program(QMLLINT_EXECUTABLE NAMES qmllint qmllint6)
if(QMLLINT_EXECUTABLE)
    file(GLOB_RECURSE QML_FILES "${CMAKE_CURRENT_SOURCE_DIR}/*.qml")
    add_custom_target(lint
        COMMAND ${QMLLINT_EXECUTABLE} ${QML_FILES}
        COMMENT "Running qmllint on all QML files..."
    )
    message(STATUS "qmllint found: enable with 'cmake --build <dir> --target lint'")
endif()

