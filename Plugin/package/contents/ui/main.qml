/*
 * This file is part of OpenWallpaper Plasma.
 * 
 * OpenWallpaper Plasma is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * OpenWallpaper Plasma is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * Full license: https://github.com/Samsuper12/OpenWallpaper-Plasma/blob/master/LICENSE
 * Copyright (C) 2020- by Michael Skorokhodov bakaprogramm29@gmail.com
 */

import QtQuick 2.12
import QtQuick.Controls 2.12 as QQC2
import QtMultimedia 5.12 as QM

import org.kde.plasma.core 2.0
import org.kde.taskmanager 0.1 as TaskManager

import OpenWallpaper.Plasma 0.1

Item {
    id: root

    // OGL is dafault
    property int currentType: 1; 
    property bool haveMusicQml: false;
    
    property real volumeFromPlasma: wallpaper.configuration.Volume;
    property string packageFromPlasma: wallpaper.configuration.Package;
    
    onVolumeFromPlasmaChanged:      { wClass.setMusicVolume(volumeFromPlasma);    }
    onPackageFromPlasmaChanged:     { wClass.setPackage(packageFromPlasma);       }
    
    
    Rectangle {
        id: oglWallpaper
        visible: true;
        anchors.fill: parent;
        
        WDesktop {
            id: wClass
            anchors.fill: parent;
        
            SequentialAnimation {
                id: wAnim
            }
        }
    }
    
    // idea of "double player" - https://store.kde.org/p/1316299
    // i don't know why QML classes are so... unfinished.
    
    Rectangle {
        id: videoWallpaper;
        anchors.fill: parent;
        
        visible: false;
        
        QM.Video {
            id: vidBackground;
            anchors.fill: parent;
            
            autoPlay: false;
            muted: true;
            loops: QM.MediaPlayer.Infinite;
        }
        
         QM.Video {
            id: vidAbove;
            anchors.fill: parent;
            
            autoPlay: false;
            loops: QM.MediaPlayer.Infinite;
        }
        
        function vLoop(value) {
            vidAbove.loops = value ? QM.MediaPlayer.Infinite : 1;
        }
        
        function vPause() {
            vidAbove.pause();
        }
        
        function vStop() {
            vidBackground.stop();
            vidAbove.stop();
        }
        
        function vPlay() {
            vidAbove.play();
        }
        
        function vNew(src) {
            vidBackground.source = src;
            vidAbove.source = src;
            
            vidBackground.play();
            vidBackground.seek(0);
            vidBackground.pause();
            vidAbove.play();
        }
        
        function vVolume(vol) {
            vidAbove.volume = vol;
        }
        
        function vFillMode(mode) {
            vidBackground.fillMode = mode;
            vidAbove.fillMode = mode;
        }
        
        function vClean() {
            vidBackground.source = "";
            vidAbove.source = "";
        }
        
        Component.onDestruction: {
            vClean();
        }
    }
    
    AnimatedImage {
        id: gifWallpaper;
        anchors.fill: parent;
        
        playing : true;
        visible: false;
        
        Component.onDestruction: {
            source = "";
        }
    }
    
    QM.Audio {
        id:audioPlayer;
        
        autoPlay: false;
        
        Component.onDestruction: {
            source = "";
        }
    }
    
    //https://api.kde.org/4.x-api/apidox-kde-4.x/apidox-kde-4.x/workspace-apidocs/plasma-workspace/html/tasksmodel_8h.html
    TaskManager.TasksModel {

		onActiveTaskChanged: {
             wClass.checkFocus(activeTask);
		}
    }
    
    Connections {
        target: wClass;
        
        onDisableSignalQ:       {   disableRender(Render)         } 
        onEnableSignalQ:        {   enableRender(Render)          }
        onPlayingSignalQ:       {   renderPlaying(Render, Mode);  }
        onMusicVolumeSignalQ:   {   setMusicVolume(Volume)        }
        onFocusChanged:         {}
        onDebugSignalQ:         {}
        onMusicCycleChanged: {  
            if (currentType == 2) { //Video
                //videoWallpaper.vLoop(value); // in next release
                return;
            }
            audioPlayer.loops = value ? QM.Audio.Infinite : 1
        }
    }
    
    Component.onCompleted: {
        wClass.checkLastPackage();
    }
    
    function renderPlaying(type, val) { 
        switch (type) {
            case 1: 
                wClass.setOglPlaying(val ? 1 : 2);
                break;
            case 2:
                val ? videoWallpaper.vPlay() : videoWallpaper.vPause();
                break;
            case 3: gifWallpaper.paused = !val;
                break;
                    
            default: break;
        }
        
        if (haveMusicQml) {
            val ? audioPlayer.play() : audioPlayer.pause();
        }
    }
    
    function enableRender(type) {
         switch (type) {
            case 1: 
                oglWallpaper.visible = true;
                break;
            case 2:
                videoWallpaper.vClean();
                videoWallpaper.vNew("file://" + wClass.getSourcePath());
                videoWallpaper.vFillMode(wClass.getFillMode());
                videoWallpaper.visible = true;
                videoWallpaper.vVolume(wClass.getStartVolume());
                //videoWallpaper.vLoop(wClass.musicCycle);
                break;
            case 3:
                gifWallpaper.source = "file://" + wClass.getSourcePath();
                gifWallpaper.playing = true;
                gifWallpaper.visible = true;
                break;
                    
            default: break;
        }
        
        currentType = type;
        
        if (wClass.getHaveMusic()) {
            haveMusicQml = true;
            audioPlayer.source = "file://" + wClass.getMusicSourcePath()
            setMusicVolume(wClass.getStartVolume());
            audioPlayer.loops = wClass.musicCycle ? QM.Audio.Infinite : 1;
            audioPlayer.play();
        }
    }
    
    function disableRender(type) {
        switch (type) {
            case 1: 
                oglWallpaper.visible = false;
                wClass.setOglPlaying(0); // 0 - Stop;
                break;
            case 2:
                videoWallpaper.vStop();
                videoWallpaper.visible = false;
                videoWallpaper.vFillMode(0); // to default
                videoWallpaper.vClean();
                
                break;
            case 3:
                gifWallpaper.playing = false;
                gifWallpaper.visible = false;
                gifWallpaper.source = "";
                break;
                    
            default: break;
        }
        
        currentType = 0; // null render
        
        haveMusicQml = false;
        audioPlayer.stop();
        audioPlayer.source = "";
    }
    
    function setMusicVolume(vol) {
        if (currentType == 2) {   //Video
            videoWallpaper.vVolume(vol);
            return;
        }
        audioPlayer.volume = vol;
    }
}
