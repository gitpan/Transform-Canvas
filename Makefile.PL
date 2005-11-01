use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Transform::Canvas',
    VERSION_FROM      => 'lib/Transform/Canvas.pm', # finds $VERSION
    PREREQ_PM         => {Carp,SVG,Data::Dumper, }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Transform/Canvas.pm', # retrieve abstract from module
       AUTHOR         => 'Ronan Oger <ronan@roasp.com>') : ()),
);
