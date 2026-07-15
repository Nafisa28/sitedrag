import { NextRequest, NextResponse } from 'next/server'
import { supabase } from '@/lib/supabase'
import { renderToHTML, renderToCSS } from '@/lib/pageExporter'

export async function POST(
  request: NextRequest,
  { params }: { params: { siteId: string } }
) {
  try {
    const siteId = params.siteId

    // Get the site data
    const { data: site, error: siteError } = await supabase
      .from('sites')
      .select('*')
      .eq('id', siteId)
      .single()

    if (siteError) {
      console.error('Error fetching site:', siteError)
      return NextResponse.json({ error: 'Failed to fetch site' }, { status: 404 })
    }

    // Parse page_data if it's a string
    const pageData = typeof site.page_data === 'string' 
      ? JSON.parse(site.page_data) 
      : site.page_data

    // Generate HTML and CSS
    const html = renderToHTML(pageData)
    const css = renderToCSS(pageData)

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
      return NextResponse.json({ error: 'Failed to update site status' }, { status: 500 })
    }

    return NextResponse.json({
      success: true,
      publishedUrl: `https://${siteId}.dragsite.com`,
      html,
      css
    })

  } catch (error) {
    console.error('Error publishing site:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
