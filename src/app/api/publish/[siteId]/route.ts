import { NextRequest, NextResponse } from 'next/server'
import { supabase } from '@/lib/supabase'
import { renderToHTML, renderToCSS } from '@/lib/pageExporter'

export async function POST(
  request: NextRequest,
  { params }: { params: { siteId: string } }
) {
  try {
    const siteId = params.siteId
    console.log('Publish request for siteId:', siteId)

    // Get the site data
    const { data: site, error: siteError } = await supabase
      .from('sites')
      .select('*')
      .eq('id', siteId)
      .single()

    if (siteError) {
      console.error('Error fetching site:', siteError)
      return NextResponse.json({ error: 'Failed to fetch site', details: siteError.message }, { status: 404 })
    }

    console.log('Site fetched successfully:', site)

    // Parse page_data if it's a string
    const pageData = typeof site.page_data === 'string'
      ? JSON.parse(site.page_data)
      : site.page_data

    console.log('Page data parsed:', pageData)

    // Generate HTML and CSS
    let html, css
    try {
      html = renderToHTML(pageData)
      css = renderToCSS(pageData)
      console.log('HTML and CSS generated successfully')
    } catch (renderError) {
      console.error('Error rendering HTML/CSS:', renderError)
      return NextResponse.json({ error: 'Failed to render site content', details: String(renderError) }, { status: 500 })
    }

    // Update site status to published
    const { error: updateError } = await supabase
      .from('sites')
      .update({
        status: 'published',
        published_url: `https://${siteId}.dragsite.com`,
        updated_at: new Date().toISOString()
      })
      .eq('id', siteId)

    if (updateError) {
      console.error('Error updating site status:', updateError)
      return NextResponse.json({ error: 'Failed to update site status', details: updateError.message }, { status: 500 })
    }

    console.log('Site published successfully')

    return NextResponse.json({
      success: true,
      publishedUrl: `https://${siteId}.dragsite.com`,
      html,
      css
    })

  } catch (error) {
    console.error('Error publishing site:', error)
    return NextResponse.json({ error: 'Internal server error', details: String(error) }, { status: 500 })
  }
}
