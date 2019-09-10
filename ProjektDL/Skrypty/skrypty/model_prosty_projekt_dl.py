import argparse
import logging

from keras import backend as K
from keras.callbacks import TensorBoard
from keras.layers import Conv2D, MaxPool2D
from keras.layers import Activation, Dropout, Flatten, Dense
from keras.models import Sequential
from keras.optimizers import RMSprop
from keras.preprocessing.image import ImageDataGenerator


def create_model(params):
    input_shape = (params.img_height, params.img_width, 3)

    model = Sequential()
    model.add(Conv2D(32, (3, 3), input_shape=input_shape))
    model.add(MaxPool2D(pool_size=(2, 2))),
    model.add(Dropout(params.drop_rate)),

    model.add(Conv2D(filters=64, kernel_size=(4, 4), activation='relu')),
    model.add(MaxPool2D(pool_size=(2, 2))),
    #model.add(Dropout(params.drop_rate)),

    model.add(Conv2D(filters=64, kernel_size=(4, 4), activation='relu')),
    model.add(MaxPool2D(pool_size=(2, 2))),
    #model.add(Dropout(params.drop_rate)),

    model.add(Conv2D(filters=32, kernel_size=(4, 4), activation='relu')),
    model.add(MaxPool2D(pool_size=(2, 2))),
    #model.add(Dropout(0.2)),

    model.add(Flatten()),
    model.add(Dense(256, activation='relu')),
    #model.add(Dropout(0.5)),
    model.add(Dense(20, activation='softmax'))

    model.compile(loss='categorical_crossentropy',
                  optimizer='adam', #RMSprop(lr=params.learning_rate),
                  metrics=['accuracy'])

    return model


def create_data_generators(params):
    # this is the augmentation configuration we will use for training
    train_datagen = ImageDataGenerator(
        rescale=1. / 255,
        shear_range=params.shear_range,
        zoom_range=params.zoom_range,
        horizontal_flip=True)

    # this is the augmentation configuration we will use for testing (only rescaling)
    test_datagen = ImageDataGenerator(rescale=1. / 255)

    train_generator = train_datagen.flow_from_directory(
        params.train_data_dir,
        target_size=(params.img_height, params.img_width),
        batch_size=params.batch_size)

    validation_generator = test_datagen.flow_from_directory(
        params.val_data_dir,
        target_size=(params.img_height, params.img_width),
        batch_size=params.batch_size)

    return train_generator, validation_generator


def train_model(model, train_generator, validation_generator, params):
    # fit model
    return model.fit_generator(
        train_generator,
        steps_per_epoch=params.nb_train_samples // params.batch_size,
        epochs=params.epochs,
        validation_data=validation_generator,
        validation_steps=params.nb_val_samples // params.batch_size,
        workers=params.workers,
        callbacks=[TensorBoard(log_dir=params.log_dir)])


def main(params):
    log = logging.getLogger('small_convnet')

    model = create_model(params)
    log.debug("Created model:")
    model.summary(print_fn=lambda x: log.debug(x))

    if params.resume_run:
        model.load_weights(params.save_path)
        log.info("Loaded weights from: %s", params.save_path)

    train_generator, validation_generator = create_data_generators(params)
    log.info("Created training and test data generators.")

    train_model(model, train_generator, validation_generator, params)
    log.info("Training finished!")

    model.save(params.save_path)
    log.info("Saved weights to: %s", params.save_path)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--train_data_dir', type=str, default=r'.\oregon_wildlife\train',
                        help="Path to directory with training data.")
    parser.add_argument('--nb_train_samples', type=int, default=12013,
                        help="Number of training samples.")
    parser.add_argument('--val_data_dir', type=str, default=r'.\oregon_wildlife\validation',
                        help="Path to directory with test data.")
    parser.add_argument('--nb_val_samples', type=int, default=2000,
                        help="Number of test samples.")
    parser.add_argument('--img_height', type=int, default=200,
                        help="Images will be resized to this height.")
    parser.add_argument('--img_width', type=int, default=200,
                        help="Images will be resized to this width.")
    parser.add_argument('--epochs', type=int, default=50,
                        help="Epochs of training.")
    parser.add_argument('--batch_size', type=int, default=32,
                        help="Batch size.")
    parser.add_argument('--workers', type=int, default=4,
                        help="Maximum number of that will execute the generator.")
    parser.add_argument('--learning_rate', type=float, default=0.001,
                        help="RMSprop learning rate.")
    parser.add_argument('--drop_rate', type=float, default=0.1,
                        help="Dense layer dropout rate.")
    parser.add_argument('--shear_range', type=float, default=0.2,
                        help="Shear intensity (angle) in counter-clockwise direction in degrees.")
    parser.add_argument('--zoom_range', type=float, default=0.2,
                        help="Range for random zoom: [1 - zoom_range, 1 + zoom_range].")
    parser.add_argument('--log_dir', type=str, default=r'.\logs',
                        help="Where to save TensorBoard logs.")
    parser.add_argument('--save_path', type=str, default=r'.\model\model_ProjektDL.h5',
                        help="Where to save model weights after training.")
    parser.add_argument('--resume_run', action='store_const', const=True, default=False,
                        help='Load the model weights and continue training.')
    parser.add_argument('--debug', action='store_const', const=True, default=False,
                        help='Set debug logging level, otherwise info level is set.')
    params = parser.parse_args()


    # configure logger
    logger = logging.getLogger('small_convnet')
    logger.setLevel(logging.DEBUG)
    ch = logging.StreamHandler()  # console handler
    ch.setLevel(logging.DEBUG if params.debug else logging.INFO)
    ch.setFormatter(logging.Formatter(fmt='%(asctime)s [%(name)s:%(levelname)s]: %(message)s',
                                      datefmt="%H:%M:%S"))
    logger.addHandler(ch)

    main(params)
