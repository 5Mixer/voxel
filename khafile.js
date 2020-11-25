let project = new Project('Blocks');

project.addShaders('Shaders/**');
project.addAssets('Assets/**');
project.addLibrary("hxWebSockets");
project.addSources('Sources');

resolve(project);
