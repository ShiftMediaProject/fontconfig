/*
 * fontconfig/fc-fontations/mod.rs
 *
 * Copyright 2025 Google LLC.
 *
 * Permission to use, copy, modify, distribute, and sell this software and its
 * documentation for any purpose is hereby granted without fee, provided that
 * the above copyright notice appear in all copies and that both that
 * copyright notice and this permission notice appear in supporting
 * documentation, and that the name of the author(s) not be used in
 * advertising or publicity pertaining to distribution of the software without
 * specific, written prior permission.  The authors make no
 * representations about the suitability of this software for any purpose.  It
 * is provided "as is" without express or implied warranty.
 *
 * THE AUTHOR(S) DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE,
 * INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO
 * EVENT SHALL THE AUTHOR(S) BE LIABLE FOR ANY SPECIAL, INDIRECT OR
 * CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE,
 * DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
 * TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
 * PERFORMANCE OF THIS SOFTWARE.
 */

extern crate fc_fontations_bindgen;

mod pattern_bindings;

use fc_fontations_bindgen::{
    fcint::{FcPatternCreate, FcPatternObjectAddBool, FC_COLOR_OBJECT},
    FcFontSet, FcFontSetAdd,
};

#[no_mangle]
/// Externally called in fcfontations.c as the file scanner function
/// similar to the job that FreeType performs.
///
/// # Safety
/// * At this point, the font file path is not dereferenced.
/// * In this initial sanity check mock call, only one empty pattern
///   is added to the FontSet, which is null checked, which is sound.
pub unsafe extern "C" fn add_patterns_to_fontset(
    _: *const libc::c_char,
    font_set: *mut FcFontSet,
) -> libc::c_int {
    let empty_pattern = FcPatternCreate();
    // Test call to ensure that an FcPrivate API function FcPatternObjectAddBool
    // is accessible and can be linked to.
    FcPatternObjectAddBool(empty_pattern, FC_COLOR_OBJECT as i32, 0_i32);
    if !font_set.is_null() {
        FcFontSetAdd(
            font_set,
            empty_pattern as *mut fc_fontations_bindgen::FcPattern,
        )
    } else {
        0
    }
}

#[cfg(test)]
mod test {
    use crate::add_patterns_to_fontset;
    use fc_fontations_bindgen::{FcFontSetCreate, FcFontSetDestroy};

    #[test]
    fn basic_pattern_construction() {
        unsafe {
            let font_set = FcFontSetCreate();
            assert!(add_patterns_to_fontset(std::ptr::null(), font_set) == 1);
            FcFontSetDestroy(font_set);
        }
    }
}
