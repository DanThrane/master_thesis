include "jpm_database.iol"
include "database.iol"
include "string_utils.iol"
include "console.iol"

execution { concurrent }

inputPort JPMDatabase {
    Location: "local"
    Interfaces: JPMDatabaseIface
}

constants {
    DATABASE_INIT_1 = "
CREATE TABLE IF NOT EXISTS jpm_specs
(
  name          TEXT    NOT NULL COLLATE NOCASE,
  version_major INT     NOT NULL,
  version_minor INT     NOT NULL,
  version_patch INT     NOT NULL,
  version_label TEXT,
  description   TEXT,
  source_name   TEXT    NOT NULL,
  source_commit TEXT,
  private       BOOLEAN NOT NULL,
  CONSTRAINT jpm_specs_name_version_major_version_minor_version_patch_pk 
  PRIMARY KEY (name, version_major, version_minor, version_patch)
);    ",

    DATABASE_INIT_2 = "
CREATE TABLE IF NOT EXISTS jpm_specs_dependencies
(
  name          TEXT NOT NULL,
  module        TEXT NOT NULL,
  version_major INT  NOT NULL,
  version_minor INT  NOT NULL,
  version_patch INT  NOT NULL,
  version       TEXT,

  CONSTRAINT jpm_specs_dependencies_jpm_specs_name_fk FOREIGN KEY (name)
  REFERENCES jpm_specs (name),

  PRIMARY KEY (name, version_major, version_minor, version_patch, module),

  FOREIGN KEY (name, version_major, version_minor, version_patch)
  REFERENCES jpm_specs (name, version_major, version_minor, version_patch)
);
   ",

    DATABASE_INSERT_SPEC = "
INSERT OR REPLACE INTO jpm_specs
(name, description, version_major, version_minor, version_patch,
 version_label, source_name, source_commit, private)
VALUES
  (:name, :description, :version_major, :version_minor, :version_patch,
   :version_label, :source_name, :source_commit, :private);
    ",

    DATABASE_INSERT_SPEC_DEPENDENCY = "
INSERT OR REPLACE INTO jpm_specs_dependencies
(name, version_major, version_minor, version_patch, module, version)
VALUES
  (:name, :version_major, :version_minor, :version_patch, :module, :version);
    ",

    DATABASE_SEARCH_QUERY = "
SELECT DISTINCT *
FROM jpm_specs
WHERE name LIKE :q
GROUP BY name
ORDER BY
  version_major
  DESC,
  version_minor
  DESC,
  version_patch
  DESC;    
    ",

    DATABASE_FIND_QUERY = "
SELECT *
FROM jpm_specs
WHERE name = :name AND 
      version_major = :version_major AND 
      version_minor = :version_minor AND
      version_patch = :version_patch;
    ",

    DATABASE_FIND_DEPENDENCIES = "
    SELECT *
    FROM jpm_specs_dependencies
    WHERE name = :name AND
          version_major = :version_major AND
          version_minor = :version_minor AND
          version_patch = :version_patch;
    "
}

define row_to_module
{
    with (mapped_module) {
        .name = row.name;
        .description = row.description;
        .source.module = row.source_name;
        .source.version = row.source_commit;
        .version.major = row.version_major;
        .version.minor = row.version_minor;
        .version.patch = row.version_patch;
        .version.label = row.version_label;
        .private = row.private
    }
}

main
{
    [connect(home)(res) {
        with (connectionInfo) {
            .username = .password = .host = "";
            .database = home + "/local.db";
            .driver = "sqlite"
        };
        connect@Database(connectionInfo)();

        update@Database(DATABASE_INIT_1)(ret);
        update@Database(DATABASE_INIT_2)(ret)
    }]

    [insertModule(module)(res) {
        query = DATABASE_INSERT_SPEC;
        with (query) {
            .name = module.name;
            .description = module.description;
            .version_major = module.version.major;
            .version_minor = module.version.minor;
            .version_patch = module.version.patch;
            if (is_defined(module.version.label)) {
                .version_label = module.version.label
            };
            .source_name = module.source.module;
            .source_commit = module.source.version;
            .private = module.private
        };
        update@Database(query)(ret);

        for (j = 0, j < #module.dependencies, j++) {
            dep -> module.dependencies[j];
            query = DATABASE_INSERT_SPEC_DEPENDENCY;
            with (query) {
                .name = module.name;
                .version_major = module.version.major;
                .version_minor = module.version.minor;
                .version_patch = module.version.patch;
                .module = dep.module;
                .version = dep.version
            };
            update@Database(query)(ret)
        }
    }]

    [search(request)(response) {
        query = DATABASE_SEARCH_QUERY;
        with (query) {
            .q = "%" + request + "%"
        };
        query@Database(query)(results);

        output -> response.results;
        for (i = 0, i < #results.row, i++) {
            row -> results.row[i];
            row_to_module;
            output[i] << mapped_module
        }
    }]

    [find(query)(response) {
        query = DATABASE_FIND_QUERY;
        query << query;

        query@Database(query)(results);

        if (#results.row != 1) {
            response.found = false
        } else {
            row -> results.row[0];
            row_to_module;
            result -> mapped_module;

            query = DATABASE_FIND_DEPENDENCIES;
            query << query;
            query@Database(query)(dependencyResults);

            for (i = 0, i < #dependencyResults.row, i++) {
                row -> dependencyResults.row[i];
                with (result.dependencies[i]) {
                    .module = row.module;
                    .version = row.version
                }
            };

            response.result << result;
            response.found = true
        }
    }]
}
