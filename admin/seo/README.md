# Kota Kurtis SEO workspace

Open `/admin/seo/` on a local preview or the deployed site. Product records come from the existing catalog in `script.js`. After Supabase is configured, SEO edits, keywords, templates, and content plans are stored in the protected `seo_workspace` database row.

## Static hosting limits

The storefront remains static on GitHub Pages. Supabase Auth handles administrator sign-in and Postgres Row Level Security protects every workspace read and write. The page shell itself is public, but no SEO data is released to a browser until the signed-in user is present in `seo_admins`; the browser's publishable key is not an admin credential. Never put a service-role key or database password in the site.

Local SEO drafts do not publish into storefront HTML. Product detail pages update the browser's title, description, canonical URL, and Open Graph values from the selected catalog entry at runtime. Static hosting cannot render a distinct product page for each query parameter on the server, and a browser-side metadata change alone does not provide reliable crawler rendering. For production edits and distinct crawlable product URLs, move product/page content into a CMS or database and render static product pages during a trusted build, or use a server-rendered storefront with an authenticated admin API.

## Supabase setup

1. Create a Supabase project and run [`/supabase/schema.sql`](../../supabase/schema.sql) in its SQL Editor.
2. In Authentication settings, disable public sign-ups. Create or invite your own user from the Supabase dashboard and enable email confirmation.
3. In the Authentication users list, copy your user's UUID. In SQL Editor, run `insert into public.seo_admins (user_id) values ('YOUR-USER-UUID');` replacing the placeholder with that UUID.
4. Copy the project's HTTPS URL and **publishable** key into `url` and `publishableKey` in `admin/seo/supabase-config.js`. The publishable key is intended for browsers; never use a secret or service-role key.
5. Commit and deploy the config file. Open `/admin/seo/` and sign in with the invited admin account.

The site doesn't have Supabase project credentials or an admin user yet, so the login screen remains locked until these steps are completed. Do not send passwords, database credentials, or service-role keys in chat.

## Publishing SEO changes

Workspace edits are securely stored but do not rewrite public HTML automatically. Product detail pages update browser title, description, canonical URL, and Open Graph values from the selected catalog record at runtime. A static query-parameter product page still limits reliable distinct crawler rendering. To publish metadata edits reliably, add a trusted build step that reads the protected database and generates pages, or move the storefront to a server-rendered CMS. The sitemap and `robots.txt` tools download files for manual review; they do not deploy them. Search Console, Analytics, and Tag Manager remain unconnected until configured through a protected OAuth flow.
