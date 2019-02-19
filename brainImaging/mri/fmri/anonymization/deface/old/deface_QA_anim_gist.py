import matplotlib.pyplot as plt
import matplotlib.animation as animation
import nibabel as nib
import numpy as np
import os.path as op


# get data and mask RGBAs, oriented as necessary for mosaics/animations
# (** not used for any other purpose! **)
def get_data_mask(raw, defaced):
    raw_nii = nib.load(raw)
    raw_data = raw_nii.get_data().astype(np.float32)
    deface_nii = nib.load(defaced)
    deface_data = deface_nii.get_data().astype(np.float32)
    mask = deface_data != raw_data
    #
    (i0,i1), (j0,j1), (k0,k1) = [(x.min(), x.max()) for x in np.where(raw_data > 10.0)] #arbitrary threshold
    k0 = max(np.where(mask)[2].min()-5,0)
    k1 = min(np.where(mask)[2].max()+5, mask.shape[2])
    raw_data = raw_data[i0:i1,j0:j1,k0:k1]
    mask = mask[i0:i1,j0:j1,k0:k1]
    mask_rgba = mask2RGBA(mask)
    raw_data = np.swapaxes(raw_data, 0, 1)[::-1,:,::-1]
    mask_rgba = np.swapaxes(mask_rgba, 0, 1)[::-1,:,::-1,:]
    return raw_data, mask_rgba

def alpha_blend(fg, bg, afg = 0.5, abg = 1.0):
    ao = afg + abg * (1-afg)
    xo = (fg * afg + bg * abg * (1-afg)) / ao
    return np.c_[xo, ao*np.ones_like(xo[...,:1])]

def mask2RGBA(mask, color = (1., 0., 0.), alpha = 0.7):
    mask_flatvox = mask.flatten() #np.reshape(np.transpose(rois, axes=[1,2,3,0]), (np.prod(rois.shape[1:]), rois.shape[0]))
    rgba_flatvox = np.zeros((mask_flatvox.shape[0],4))
    rgba_flatvox[np.where(mask_flatvox)] = np.r_[color, alpha]
    maskRGBA = rgba_flatvox.reshape(mask.shape+(4,))
    return maskRGBA

# Plot an image mosaic of the defaced T1 with mask overlaid
def deface_mosaic(raw, defaced, output_dir):
    raw_data, mask_rgba = get_data_mask(raw, defaced)
    # 5th/95th percentile vmin, vmax
    v0, v1 = np.percentile(raw_data[(raw_data !=0 ) & np.isfinite(raw_data)], [5, 95])
    fig0 = plt.figure(figsize=(11.25,7.5), frameon=False)
    grid_len = np.ceil(np.sqrt(raw_data.shape[2])).astype(np.int)
    mosaic_mask_image(raw_data,
                      mask_rgba,
                      fig = fig0,
                      gridsize=2*(grid_len,), 
                      vmin = v0, 
                      vmax=v1)
    fig0.set_facecolor('black')
    raw_name = op.basename(raw).split('.')[0]
    plt.savefig(op.join(figure_dir, '%s_T1_deface_mosaic.png' % raw_name), facecolor = 'black', dpi=600)
    plt.close(fig0)

# Winsorize and normalize to [0,1]
def winsormalize(data, percentile = [5, 95]):
    v0, v1 = np.percentile(data[(data !=0 ) & np.isfinite(data)], [5, 95])
    data[data>v1] = v1
    data[data<v0] = v0
    data = (data - data.min()) / (data.max() - data.min())
    return data


# plot a .gif animation of the defaced image w/ mask
#TODO: get the voxel dims and set the aspect ratio accordingly
def deface_ani(raw, defaced, output_dir, prefix):
    data, mask_rgba = get_data_mask(raw, defaced)
    data = winsormalize(data)
    #zooms = nib.load(raw).get_header().get_zooms()
    #yscale = 2*data.shape[1]*zooms[0]/(data.shape[0]*zooms[1])
    #fig = plt.figure(figsize=(4.*yscale, 8), frameon=False)
    fig = plt.figure(figsize=(4., 4), frameon=False)
    #
    ax = plt.Axes(fig, [0., 0., 1., 1.])
    fig.add_axes(ax)
    # data = np.transpose(data, axes = [2,0,1])[::-1,...]
    # mask_rgba = np.transpose(mask_rgba, axes = [2,0,1,3])[::-1,...]
    cm = plt.get_cmap('Greys_r')
    data_rgba = cm(data)
    merged_rgba = alpha_blend(mask_rgba[...,:3], data_rgba[...,:3], afg = 0.5)
    im = ax.imshow(np.zeros_like(data_rgba[:,:,0,:]), interpolation = 'none', animated=True, aspect='auto')
    ax.set_axis_off()
        #
    def update(i):
        im.set_data( merged_rgba[:,:,i,:] )
        #
    ani = animation.FuncAnimation(fig, 
                                  func=update, #init_func = init,
                                  frames=np.arange(data.shape[-1]),
                                  interval=150,
                                  repeat = False)
    #
    #raw_name = op.basename(raw).split('.')[0]
    out_name = op.join(output_dir,'%s_axi_checkT1deface.gif' % prefix)
    print('writing %s' % out_name)
    ani.save(out_name, writer='imagemagick', dpi=300)
    plt.close(fig)


raw = '/hd1/scsnl/data/face_blur_worked/spgr_1.nii.gz'
defaced = '/hd1/scsnl/data/face_blur_worked/spgr_1_defaced.nii.gz'
figure_dir = '/hd1/scsnl/data/face_blur_worked'
deface_ani(raw, defaced, figure_dir, 'spgr_1')