# Kota Kurtis SEO workspace

Open `/admin/seo/` on a local preview or the deployed site. Product records come from the existing catalog in `script.js`. SEO edits, keywords, templates, and content plans are saved in the current browser's `localStorage`; use the JSON backup to move them manually.

## Static hosting limits

This repository contains a static HTML, CSS, and JavaScript storefront and a `CNAME` for `kotakurtis.shop`. It has no application server, database, session management, or API. The admin page is therefore a local development tool, not a secure production admin: its routes are public and local storage can be edited by the browser owner. Do not enter secrets here.

Local SEO drafts do not publish into storefront HTML. Product detail pages update the browser's title, description, canonical URL, and Open Graph values from the selected catalog entry at runtime. Static hosting cannot render a distinct product page for each query parameter on the server, and a browser-side metadata change alone does not provide reliable crawler rendering. For production edits and distinct crawlable product URLs, move product/page content into a CMS or database and render static product pages during a trusted build, or use a server-rendered storefront with an authenticated admin API.

## Production architecture needed

- Add an identity provider or server-side session authentication and enforce administrator roles on every write endpoint.
- Store metadata and audit history in a database; validate and sanitize values on the server.
- Add a publishing path that regenerates/deploys storefront HTML, canonical URLs, sitemap, and structured data.
- Connect Search Console, Analytics, or Tag Manager through server-side OAuth. Keep tokens in protected server storage; never ship them to the browser.

The sitemap and `robots.txt` controls in the workspace download files for manual review and deployment. They do not upload or publish those files. Google performance and indexing data are not shown without an authorized connection.
