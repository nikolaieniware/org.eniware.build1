# EniwareEdge Application

This directory contains the build script for generating the base EniwareEdge
Application. The build requires [Apache Ant][ant].

## Configuration Setup

The build requires some configuration to run. Copy the `example/ivy.xml` file
into this directory first. Then you can modify the new copy (it will be
ignored by version control).

## Ivy Configuration

The build script assembles all the various artifacts that make up the EniwareEdge
Application using Apache Ivy. The **ivy.xml** file configures which artifacts to
include in the build. Typically you might customize this to add additional 
artifacts not already included in the application.

## Building

To build the application, run the **archive** task:

	ant archive
	
This will produce a platform tarball at `build/Edge-bundles.tgz`. To
rebuild always from scratch, add the **clean** task:

	ant clean archive

You can maintain multiple packages by creating other Ivy XML files. For example
to maintain a package with all the bundles required you could create a 
**ivy-mycompany.xml** file and then run the build like this:

	ant -Divy.file=ivy-mycompany.xml clean archive

## Upgrading Edges

To upgrade an existing Edge with a new application version, [follow the process
outlined on the EniwareNetwork wiki][upgrade].

 
  [ant]: https://ant.apache.org/
  
 [upgrade]: https://github.com/EniwareNetwork/eniwarenetwork/wiki/EniwareEdge-Manual-Platform-Update
 