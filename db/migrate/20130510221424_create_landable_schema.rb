class CreateLandableSchema < ActiveRecord::Migration
  def change
    # This really should not be in this migration, but it's a convenient location
    # while everything's still under development.
    #
    # TODO extract to a separate migration, check if it exists, maybe check if we
    # actually have permission to do it, etc.
    enable_extension "uuid-ossp"
    enable_extension "hstore"

    # Currently prevents creation of Pages due to apparent AR4 bug:
    # execute " DROP DOMAIN IF EXISTS uri;
    #           CREATE DOMAIN uri AS TEXT
    #           CHECK(
    #             VALUE ~ '^/[a-zA-Z0-9/_.~-]*$'
    #           );"

    execute "DROP SCHEMA IF EXISTS landable; CREATE SCHEMA landable;"

    create_table 'landable.pages', id: :uuid, primary_key: :page_id do |t|
      t.uuid      :published_revision_id

      # t.column "path", :uri, null: false
      t.text      :path, null: false
      t.text      :theme_name

      t.text      :title
      t.text      :body

      t.integer   :status_code, null: false, default: 200
      t.text      :redirect_url

      t.hstore    :meta_tags

      t.timestamp :imported_at
      t.timestamps
    end

    add_index 'landable.pages', :path, unique: true

    create_table 'landable.authors', id: :uuid, primary_key: :author_id do |t|
      t.text :email,      null: false
      t.text :username,   null: false
      t.text :first_name, null: false
      t.text :last_name,  null: false
      t.timestamps
    end

    create_table 'landable.access_tokens', id: :uuid, primary_key: :access_token_id do |t|
      t.uuid      :author_id,  null: false
      t.timestamp :expires_at, null: false
      t.timestamps
    end

    create_table 'landable.page_revisions', id: :uuid, primary_key: :page_revision_id do |t|
      t.integer   :ordinal

      t.uuid      :page_id, null: false
      t.uuid      :author_id, null: false

      t.text      :page_path, null: false
      t.text      :page_theme_name

      t.text      :page_title
      t.text      :page_body

      t.integer   :page_status_code, null: false, default: 200
      t.text      :page_redirect_url

      t.hstore    :page_meta_tags

      t.timestamps
    end

    # Foreign keys for page_revisions
    execute "ALTER TABLE landable.page_revisions ADD CONSTRAINT page_id_fk FOREIGN KEY (page_id) REFERENCES landable.pages(page_id)"
    execute "ALTER TABLE landable.page_revisions ADD CONSTRAINT author_id_fk FOREIGN KEY (author_id) REFERENCES landable.authors(author_id)"

    execute "ALTER TABLE landable.pages ADD CONSTRAINT revision_id_fk FOREIGN KEY (published_revision_id) REFERENCES landable.page_revisions(page_revision_id)"

    # TODO: Add proper database checks/constraints/validations on columns
    # Manually add CHECK constraints for valid URIs until we can get the custom domain working
    execute "ALTER TABLE landable.pages ADD CONSTRAINT only_valid_paths CHECK (path ~ '^/[a-zA-Z0-9/_.~-]*$');"

    # landable.pages:
    execute "ALTER TABLE landable.pages ADD CONSTRAINT only_valid_status_codes CHECK (status_code IN (200,301,302,404))"
    # => redirect_url: points to an existing page (FK)
    # => theme_name: points to existing theme (FK)

    # Revision-tracking trigger to automatically update ordinal
    execute "CREATE FUNCTION pages_revision_ordinal()
      RETURNS TRIGGER
      AS
      $TRIGGER$
        BEGIN

        NEW.ordinal = (SELECT COALESCE(MAX(ordinal)+1,1)
                        FROM landable.page_revisions
                        WHERE page_id = NEW.page_id);

        RETURN NEW;

        END
       $TRIGGER$
       LANGUAGE plpgsql;"

      execute "CREATE TRIGGER page_revivions_bfr_insert 
              BEFORE INSERT ON landable.page_revisions
              FOR EACH ROW EXECUTE PROCEDURE pages_revision_ordinal();"

  end
end
