module ApplicationHelper
  def sort_indicator_class(current_sort, field, direction = nil)
    if current_sort == "#{field} #{direction}".strip
      "text-indigo-600"
    else
      "text-gray-400 group-hover:text-gray-500"
    end
  end

  def sort_arrow_icon(current_sort, field, direction = nil)
    if current_sort == "#{field} #{direction}".strip
      if direction == "desc"
        # Down arrow for descending
        '<svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M14.707 12.707a1 1 0 01-1.414 0L10 9.414l-3.293 3.293a1 1 0 01-1.414-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 010 1.414z" clip-rule="evenodd" /></svg>'.html_safe
      else
        # Up arrow for ascending
        '<svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M5.293 9.293a1 1 0 011.414 0L10 12.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd" /></svg>'.html_safe
      end
    else
      # Default sort icon
      '<svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd" /></svg>'.html_safe
    end
  end

  # s1920: Image size (width or height)
  # c: Crop to fit
  # rp: Rounded photo (often used for profile pics)
  # mo: Mobile-optimized (used on Maps mobile)
  # ba4, ba6, etc.: Likely background style variants (undocumented but used for styling)
  # br100: Border-radius 100% (makes the image fully round)
  def profile_image_url(url)
    url.gsub('s1920', 's75')
  end

  def notification_icon(notification_type)
    case notification_type.to_s
    when 'review'
      content_tag :div, class: "flex-shrink-0 w-8 h-8 rounded-full bg-yellow-100 flex items-center justify-center mr-3" do
        content_tag :svg, class: "size-4 text-yellow-600", fill: "currentColor", viewBox: "0 0 20 20" do
          content_tag :path, nil, d: "M7.5 8.25h9m-9 3H12m-9.75 1.51c0 1.6 1.123 2.994 2.707 3.227 1.129.166 2.27.293 3.423.379.35.026.67.21.865.501L12 21l2.755-4.133a1.14 1.14 0 0 1 .865-.501 48.172 48.172 0 0 0 3.423-.379c1.584-.233 2.707-1.626 2.707-3.228V6.741c0-1.602-1.123-2.995-2.707-3.228A48.394 48.394 0 0 0 12 3c-2.392 0-4.744.175-7.043.513C3.373 3.746 2.25 5.14 2.25 6.741v6.018Z"
        end
      end
    when 'complain'
      content_tag :div, class: "flex-shrink-0 w-8 h-8 rounded-full bg-red-100 flex items-center justify-center mr-3" do
        content_tag :svg, class: "size-4 text-red-600", fill: "currentColor", viewBox: "0 0 20 20" do
          content_tag :path, nil, fill_rule: "evenodd", d: "M8.485 2.495c.673-1.167 2.357-1.167 3.03 0l6.28 10.875c.673 1.167-.17 2.625-1.516 2.625H3.72c-1.347 0-2.189-1.458-1.515-2.625L8.485 2.495zM10 5a.75.75 0 01.75.75v3.5a.75.75 0 01-1.5 0v-3.5A.75.75 0 0110 5zm0 9a1 1 0 100-2 1 1 0 000 2z", clip_rule: "evenodd"
        end
      end
    when 'suggestion'
      content_tag :div, class: "flex-shrink-0 w-8 h-8 rounded-full bg-blue-100 flex items-center justify-center mr-3" do
        content_tag :svg, class: "size-4 text-blue-600", fill: "currentColor", viewBox: "0 0 20 20" do
          content_tag :path, nil, d: "M10 2C5.58 2 2 5.58 2 10c0 1.85.63 3.55 1.69 4.9L2.3 17.3c-.39.39-.39 1.02 0 1.41.39.39 1.02.39 1.41 0l2.4-2.4C7.45 17.37 8.65 18 10 18c4.42 0 8-3.58 8-8s-3.58-8-8-8zm1 13h-2v-2h2v2zm0-4h-2V7h2v4z"
        end
      end
    when 'keyword'
      content_tag :div, class: "flex-shrink-0 w-8 h-8 rounded-full bg-green-100 flex items-center justify-center mr-3" do
        content_tag :svg, class: "size-4 text-green-600", fill: "currentColor", viewBox: "0 0 20 20" do
          content_tag :path, nil, fill_rule: "evenodd", d: "M5.5 3A2.5 2.5 0 003 5.5v2.879a2.5 2.5 0 00.732 1.767L6.5 12.914a2.5 2.5 0 001.768.732H10.5A2.5 2.5 0 0013 11.146V9.5h1.379a2.5 2.5 0 001.767-.732L18.914 6a2.5 2.5 0 000-3.536L16.146.732a2.5 2.5 0 00-3.536 0L9.843 3.5H5.5zM9 8a1 1 0 100-2 1 1 0 000 2z", clip_rule: "evenodd"
        end
      end
    else
      content_tag :div, class: "flex-shrink-0 w-8 h-8 rounded-full bg-gray-100 flex items-center justify-center mr-3" do
        content_tag :svg, class: "size-4 text-gray-600", fill: "currentColor", viewBox: "0 0 20 20" do
          content_tag :path, nil, fill_rule: "evenodd", d: "M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z", clip_rule: "evenodd"
        end
      end
    end
  end
end
