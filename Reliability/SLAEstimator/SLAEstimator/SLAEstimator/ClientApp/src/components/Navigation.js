import React, { Component } from 'react';
import './Styles.css';

export class Navigation extends Component {

    constructor(props) {
        super(props);
    }

    static renderCategoriesTable(serviceCategories, selectedCategory, selectCategory) {
        return (
            <table className='table table-striped' aria-labelledby="tabelLabel">
                <tbody>
                    {serviceCategories.map(serviceCategory =>
                        <tr key={serviceCategory.categoryName}>
                            <td className={selectedCategory === serviceCategory.categoryName ? "selectedcategorymenu-item" : "categorymenu-item"}
                                onClick={() => selectCategory(serviceCategory)}>{serviceCategory.categoryName}</td>
                        </tr>
                    )}
                </tbody>
            </table>
        );
    }

    render() {
        if (this.props.visible) {
            let contents = Navigation.renderCategoriesTable(this.props.dataSource, this.props.selectedCategory, this.props.onSelectCategory);
            return (
                <div>
                    {contents}
                </div>
            );
        }
        else {
            return (<div></div>)
        }
    }
}
