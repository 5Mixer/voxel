let project = new Project('HaxeC');
project.addFiles('kore_sources.c');
project.addFiles('Sources/**.metal');
project.addIncludeDirs('.');
resolve(project);
