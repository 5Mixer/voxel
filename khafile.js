let project = new Project('Blocks');

project.addShaders('Shaders/**');
project.addAssets('Assets/**');
project.addSources('Sources');

resolve(project);
