$activeBorderColor = rgb({{ accent_strip }})
$inactiveBorderColor = rgb({{ color8_strip }})

general {
    col.active_border = $activeBorderColor
    col.inactive_border = $inactiveBorderColor
}

group {
    col.border_active = $activeBorderColor
    col.border_inactive = $inactiveBorderColor

    groupbar {
        text_color = rgb({{ foreground_strip }})
        text_color_inactive = rgba({{ foreground_strip }}90)

        col.active = rgb({{ color8_strip }})
        col.inactive = rgb({{ background_strip }})
    }
}
