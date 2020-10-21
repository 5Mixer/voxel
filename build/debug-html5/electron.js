'use strict';

const electron = require('electron');
const app = electron.app;
const BrowserWindow = electron.BrowserWindow;

var mainWindow = null;

electron.ipcMain.on('asynchronous-message', (event, arg) => {
	if (arg.width && arg.height) mainWindow.setContentSize(arg.width, arg.height);
	if (arg.title) mainWindow.setTitle(arg.title);
	if (arg.x != -1 && arg.y != -1) {
		mainWindow.setPosition(arg.x, arg.y);
	} else {
		mainWindow.center();
	}
	mainWindow.show();
});

app.on('window-all-closed', function () {
	app.quit();
});

app.on('ready', function () {
	mainWindow = new BrowserWindow({
		width: 800, height: 600,
		show: false, useContentSize: true, autoHideMenuBar: true,
		webPreferences: {
			nodeIntegration: true
		}
	});
	mainWindow.loadURL('file://' + __dirname + '/index.html');
	mainWindow.on('closed', function() {
		mainWindow = null;
	});
});
