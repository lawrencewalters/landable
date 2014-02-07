class FixStatusCodes < ActiveRecord::Migration
  def up
    execute "DROP TRIGGER landable_page_revisions__no_update ON landable.page_revisions"

    # Find Pages with 404s, switch to 410s, publish the page!
    Landable::Page.where(status_code: 404).find_each do |page| 
      page.status_code = 410
      page.save!
    end

    # Find Remaining PageRevisions with 404s, switch to 410s!
    Landable::PageRevision.where(status_code: 404).find_each do |page| 
      page.status_code = 410
      page.save!
    end

    execute "CREATE TRIGGER landable_page_revisions__no_update
            BEFORE UPDATE OF notes, is_minor, page_id, author_id, created_at, ordinal
              , theme_id, status_code, category_id, redirect_url, body
            ON landable.page_revisions
            FOR EACH STATEMENT EXECUTE PROCEDURE landable.tg_disallow();"
  end
end