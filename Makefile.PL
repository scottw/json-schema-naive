use 5.016001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'JSON::Schema::Naive',
    VERSION_FROM      => 'lib/JSON/Schema/Naive.pm',
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/JSON/Schema/Naive.pm',
       AUTHOR         => 'Scott Wiersdorf <scott@betterservers.com>') : ()),
);
