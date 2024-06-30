let project = new Project('Blocks');

project.addShaders('Shaders/**');
project.addAssets('Assets/**');
project.addLibrary("hxnoise");
project.addSources('Sources');
project.addParameter('-dce full');

if (platform == Platform.HTML5) {
    // project.addLibrary('closure');
    // project.addDefine('closure_overwrite');
}

resolve(project);
