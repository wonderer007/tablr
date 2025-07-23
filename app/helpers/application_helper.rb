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
    url.gsub('s1920', 's65')
  end
end
